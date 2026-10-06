#!/usr/bin/env bash
# Builds a registration package: an own, in-process EmailValidator and an
# SMTP mailer at the system boundary. Registration.register is a stub.
set -euo pipefail

mkdir -p registration tests

cat > registration/__init__.py <<'EOF'
EOF

cat > registration/validator.py <<'EOF'
import re

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[a-z]{2,}$", re.IGNORECASE)


class EmailValidator:
    """Our own rule for which addresses we accept."""

    def is_valid(self, email: str) -> bool:
        return bool(_EMAIL.match(email))
EOF

cat > registration/mailer.py <<'EOF'
import smtplib
from email.message import EmailMessage


class SmtpMailer:
    """Sends mail through the company SMTP relay."""

    def __init__(self, host: str = "smtp.internal.example", port: int = 25):
        self.host = host
        self.port = port

    def send(self, to: str, subject: str, body: str) -> None:
        msg = EmailMessage()
        msg["To"] = to
        msg["From"] = "noreply@example.com"
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self.host, self.port) as smtp:
            smtp.send_message(msg)
EOF

cat > registration/service.py <<'EOF'
from dataclasses import dataclass

from registration.validator import EmailValidator


@dataclass
class Result:
    registered: bool
    reason: str = ""


class Registration:
    def __init__(self, mailer, validator: EmailValidator | None = None):
        self.mailer = mailer
        self.validator = validator or EmailValidator()

    def register(self, email: str) -> Result:
        raise NotImplementedError
EOF

cat > tests/__init__.py <<'EOF'
EOF
