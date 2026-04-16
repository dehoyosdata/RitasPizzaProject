#!/usr/bin/env python3
"""
Seed library data: 10 users (alice@university.edu … jack@university.edu), 1000 students, 2000 books, ~30k loans.
Runs when SEED_LIBRARY_DATA=true on first DB init.
"""
import logging
import os
import sys
import time
from datetime import datetime, timedelta
from random import choice, randint, random

# Ensure app is on path (for Docker: WORKDIR /app)
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv

load_dotenv()

from sqlalchemy import insert, text
from sqlalchemy.orm import Session

# Import after path setup
from app.core.db import SessionLocal, engine
from app.models import Base, Book, Loan, Student, User
from app.utils.hashing import hash_password

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

NUM_STUDENTS = 1000
NUM_BOOKS = 2000
NUM_LOANS = 30_000
NUM_USERS = 10

# 10 users with dummy names @university.edu (password: password123 for demo)
USERS_SEED = [
    ("alice", "alice@university.edu"),
    ("bob", "bob@university.edu"),
    ("charlie", "charlie@university.edu"),
    ("diana", "diana@university.edu"),
    ("eve", "eve@university.edu"),
    ("frank", "frank@university.edu"),
    ("grace", "grace@university.edu"),
    ("henry", "henry@university.edu"),
    ("iris", "iris@university.edu"),
    ("jack", "jack@university.edu"),
]
START_DATE = datetime(2026, 1, 1, 0, 0, 0)
LOAN_DURATION_DAYS = 14

# Loan outcome distribution: not returned, on-time, late
NOT_RETURNED_RATIO = 0.12
ON_TIME_RATIO = 0.73
LATE_RATIO = 0.15
assert abs(NOT_RETURNED_RATIO + ON_TIME_RATIO + LATE_RATIO - 1.0) < 0.01


def _can_connect() -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


def wait_for_db(max_attempts: int = 36, delay: int = 5) -> None:
    """Wait for DB to be reachable."""
    for i in range(1, max_attempts + 1):
        if _can_connect():
            logger.info("Database connected (attempt %d)", i)
            return
        logger.info("Waiting for DB (attempt %d/%d)...", i, max_attempts)
        time.sleep(delay)
    raise RuntimeError("Database unavailable")


def is_already_seeded(db: Session) -> bool:
    """Return True if students table has data."""
    r = db.execute(text("SELECT COUNT(*) FROM students")).scalar()
    return r > 0  # type: ignore


def seed_users(db: Session, fake=None) -> None:
    """Seed 10 users with dummy names @university.edu. Password: password123 (demo)."""
    logger.info("Seeding %d users...", NUM_USERS)
    demo_password = "password123"
    batch = [
        {"email": email, "password_hash": hash_password(demo_password)}
        for _, email in USERS_SEED[:NUM_USERS]
    ]
    db.execute(insert(User), batch)
    db.commit()
    logger.info("Users seeded (alice@university.edu ... jack@university.edu, password: %s)", demo_password)


def seed_students(db: Session, fake) -> list[int]:
    """Seed 1000 students. Returns list of student ids."""
    logger.info("Seeding %d students...", NUM_STUDENTS)
    seen = set()
    rows = []
    while len(rows) < NUM_STUDENTS:
        email = f"student{len(seen)+1}@{fake.domain_name()}"
        if email in seen:
            continue
        seen.add(email)
        rows.append(
            {
                "name": fake.name(),
                "email": email,
                "max_books_allowed": choice([2, 3, 4, 5]),
            }
        )
    db.execute(insert(Student), rows)
    db.commit()
    result = db.execute(text("SELECT id FROM students ORDER BY id")).fetchall()
    return [r[0] for r in result]


def seed_books(db: Session, fake, copies_per_book: int = 25) -> list[int]:
    """Seed 2000 books. Returns list of book ids."""
    logger.info("Seeding %d books...", NUM_BOOKS)
    prefixes = (
        "Introduction to", "Advanced", "Fundamentals of", "Practical",
        "Modern", "Essential", "Complete Guide to", "Handbook of",
    )
    subjects = (
        "Python", "JavaScript", "Databases", "Algorithms", "Machine Learning",
        "Web Development", "Data Structures", "Networking", "Security",
        "Cloud Computing", "Statistics", "Calculus", "Physics", "Chemistry",
    )
    seen_isbn = set()
    rows = []
    for _ in range(NUM_BOOKS):
        isbn = fake.isbn13()
        while isbn in seen_isbn:
            isbn = fake.isbn13()
        seen_isbn.add(isbn)
        rows.append(
            {
                "title": f"{choice(prefixes)} {choice(subjects)}",
                "isbn": isbn,
                "copies_available": copies_per_book,
            }
        )
    db.execute(insert(Book), rows)
    db.commit()
    result = db.execute(text("SELECT id FROM books ORDER BY id")).fetchall()
    return [r[0] for r in result]


def seed_loans(
    db: Session,
    student_ids: list[int],
    book_ids: list[int],
    end_date: datetime,
) -> None:
    """Seed ~30k loans with varied outcomes."""
    logger.info("Seeding %d loans...", NUM_LOANS)
    total_seconds = int((end_date - START_DATE).total_seconds())
    total_seconds = max(total_seconds, 86400)  # at least 1 day if run before 2026
    rows = []
    for _ in range(NUM_LOANS):
        student_id = choice(student_ids)
        book_id = choice(book_ids)
        borrow_offset = randint(0, max(0, total_seconds - 1))
        borrowed_at = START_DATE + timedelta(seconds=borrow_offset)
        due_date = borrowed_at + timedelta(days=LOAN_DURATION_DAYS)

        roll = random()
        if roll < NOT_RETURNED_RATIO:
            returned_at = None
        elif roll < NOT_RETURNED_RATIO + ON_TIME_RATIO:
            # On-time: return within due_date
            return_span = (due_date - borrowed_at).total_seconds()
            ret_offset = randint(0, int(return_span))
            returned_at = borrowed_at + timedelta(seconds=ret_offset)
        else:
            # Late: return after due_date
            days_late = randint(1, 30)
            returned_at = due_date + timedelta(days=days_late)
            if returned_at > end_date:
                returned_at = end_date

        rows.append(
            {
                "student_id": student_id,
                "book_id": book_id,
                "borrowed_at": borrowed_at,
                "due_date": due_date,
                "returned_at": returned_at,
            }
        )
        if len(rows) >= 2000:
            db.execute(insert(Loan), rows)
            db.commit()
            rows = []
    if rows:
        db.execute(insert(Loan), rows)
        db.commit()
    logger.info("Loans seeded.")


def update_book_copies(db: Session, copies_per_book: int = 25) -> None:
    """Set copies_available = copies_per_book - active_loans per book."""
    logger.info("Updating book copies_available...")
    counts = db.execute(
        text(
            "SELECT book_id, COUNT(*) AS c FROM loans "
            "WHERE returned_at IS NULL GROUP BY book_id"
        )
    ).fetchall()
    count_map = {r[0]: r[1] for r in counts}
    for book in db.query(Book).all():
        active = count_map.get(book.id, 0)
        book.copies_available = copies_per_book - active
    db.commit()
    logger.info("Book copies updated.")


def main() -> None:
    if os.environ.get("SEED_LIBRARY_DATA", "").lower() not in ("true", "1", "yes"):
        logger.info("SEED_LIBRARY_DATA not set to true, skipping seed.")
        return

    wait_for_db()
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        if is_already_seeded(db):
            logger.info("Data already seeded, skipping.")
            return

        from faker import Faker

        fake = Faker()
        fake.seed_instance(42)

        seed_users(db, fake)
        student_ids = seed_students(db, fake)
        book_ids = seed_books(db, fake)
        end_date = datetime.utcnow()
        seed_loans(db, student_ids, book_ids, end_date)
        update_book_copies(db)

        logger.info("Seed complete: %d users, %d students, %d books, %d loans", NUM_USERS, NUM_STUDENTS, NUM_BOOKS, NUM_LOANS)
    finally:
        db.close()


if __name__ == "__main__":
    main()
