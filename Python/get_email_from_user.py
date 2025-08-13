import imaplib
import email
import os
import logging
from datetime import datetime

from dotenv import load_dotenv

load_dotenv()

# Configuration
HOME_DIR = os.path.expanduser("~") # For default directory

EMAIL_USER = os.getenv("EMAIL_USER")
EMAIL_PASS = os.getenv("EMAIL_PASS")
IMAP_SERVER = os.getenv("IMAP_SERVER")
SENDER_MAIL = os.getenv("SENDER_MAIL")
DOWNLOAD_DIR = os.getenv("DOWNLOAD_DIR", os.path.join(HOME_DIR, "todays_attachments"))
LOG_DIR = os.getenv("LOG_DIR", os.path.join(HOME_DIR, "todays_attachments"))
LOG_FILE = ""

os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# Log file path
LOG_FILE = os.path.join(LOG_DIR, f"imap_email_{datetime.now():%Y-%m-%d}.log")
open(LOG_FILE, "a").close()

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

logging.info("Logging initialized. Download dir: %s", DOWNLOAD_DIR)

try:
    # Login to mail server
    mail = imaplib.IMAP4_SSL(IMAP_SERVER)
    mail.login(EMAIL_USER, EMAIL_PASS)
    logging.info("Logged in successfully.")

    # Select mail inbox
    mail.select("inbox")

    # Search for mails from specifc sender. Change this line if you want to change the sender.
    status, messages = mail.search(None, f'(FROM {SENDER_MAIL})', 'ALL')

    if status == "OK":
        raw_messages = messages[0].split()
        logging.info("Found %d new emails from sender: %s", len(raw_messages), SENDER_MAIL)

        for raw_message in raw_messages:
            # By using RFC822, we are fetching the entire raw message in RFC822 format.
            status, data = mail.fetch(raw_message, "(RFC822)")

            if status == "OK":
                # For RFC822, data[0][0] is metadata telling about message number and size.
                # data[0][1] is the raw RFC822 message.
                raw_data = data[0][1]
                msg = email.message_from_bytes(raw_data)

                """
                    Email can be multipart and may contain text, htmls, attachments and so on. msg.walk iterates over
                    every MIME part the email. MIME, which stands for Multipurpose Internet Mail Extensions, is a 
                    standard that allows email messages to contain various types of content beyond simple text.

                    Content-Disposition tells the email client how to display a MIME part. If MIME is text/plain HTML,
                    then Content-Disposition is None and we want to skip it since we only want to download attachments.
                """
                for part in msg.walk():
                    if part.get_content_maintype() == "multipart" or part.get("Content-Disposition") is None:
                        continue

                    filename = part.get_filename()

                    if filename:
                        filepath = os.path.join(DOWNLOAD_DIR, filename)

                        # Check for duplicate filenames
                        if os.path.exists(filepath):
                            logging.info("File %s already exists. Skipping it", filename)
                            continue
                        
                        logging.info("Found attachments: %s", filename)

                        try:
                            with open(filepath, "wb") as f:
                                # Email attachments arent sent raw: They are encoded for safe transfer. Hence, we need
                                # to decode to original raw bytes.
                                f.write(part.get_payload(decode=True))
                            logging.info("Downloaded '%s' to '%s'", filename, DOWNLOAD_DIR)
                        except Exception as e:
                            logging.error("Failed to download attachment '%s': %s", filename, e)
            else:
                logging.info("No new emails found from %s", SENDER_MAIL)
except Exception as e:
    logging.error("Unexpected error: %s.", e)

finally:
    if 'mail' in locals():
        mail.logout()
        logging.info("Connection closed.")