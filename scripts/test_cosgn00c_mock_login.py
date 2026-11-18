# -*- coding: utf-8 -*-
"""
Testes unitarios da logica de mock de login (US-20261008-001).

Espelha a decisao de COSGN00C apos UPPER-CASE e validacao de obrigatoriedade:
- ADMIN/ADMIN -> mock administrativo (sem USRSEC), destino COADM01C, tipo A
- demais pares -> fluxo real (READ-USER-SEC-FILE)
"""
from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

COSGN00C = (
    Path(__file__).resolve().parents[1] / "app" / "cbl" / "COSGN00C.cbl"
)


def normalize_credential(value: str) -> str:
    """Equivalente a FUNCTION UPPER-CASE em campo PIC X(08)."""
    return value.upper().ljust(8)[:8]


def is_blank(value: str) -> bool:
    return value.strip() == ""


def decide_login(user_id: str, password: str) -> dict:
    """
    Modelo da decisao em PROCESS-ENTER-KEY (apos RECEIVE MAP).

    Retorna dict com: path, user_type, xctl_program, message, read_usrsec.
    """
    if is_blank(user_id):
        return {
            "path": "validation",
            "message": "Please enter User ID ...",
            "read_usrsec": False,
            "xctl_program": None,
            "user_type": None,
            "user_id": None,
        }
    if is_blank(password):
        return {
            "path": "validation",
            "message": "Please enter Password ...",
            "read_usrsec": False,
            "xctl_program": None,
            "user_type": None,
            "user_id": None,
        }

    ws_user = normalize_credential(user_id)
    ws_pwd = normalize_credential(password)

    if ws_user == normalize_credential("ADMIN") and ws_pwd == normalize_credential(
        "ADMIN"
    ):
        return {
            "path": "mock",
            "message": None,
            "read_usrsec": False,
            "xctl_program": "COADM01C",
            "user_type": "A",
            "user_id": ws_user.rstrip(),
        }

    return {
        "path": "usrsec",
        "message": None,
        "read_usrsec": True,
        "xctl_program": None,
        "user_type": None,
        "user_id": ws_user.rstrip(),
    }


class TestMockLoginDecision(unittest.TestCase):
    def test_mock_admin_admin(self):
        result = decide_login("admin", "admin")
        self.assertEqual(result["path"], "mock")
        self.assertEqual(result["user_type"], "A")
        self.assertEqual(result["xctl_program"], "COADM01C")
        self.assertEqual(result["user_id"], "ADMIN")
        self.assertFalse(result["read_usrsec"])

    def test_mock_case_insensitive(self):
        result = decide_login("Admin", "Admin")
        self.assertEqual(result["path"], "mock")
        self.assertEqual(result["user_type"], "A")
        self.assertEqual(result["xctl_program"], "COADM01C")

    def test_admin_wrong_password_goes_to_usrsec(self):
        result = decide_login("admin", "errada")
        self.assertEqual(result["path"], "usrsec")
        self.assertTrue(result["read_usrsec"])

    def test_password_admin_other_user_goes_to_usrsec(self):
        result = decide_login("ADMIN001", "admin")
        self.assertEqual(result["path"], "usrsec")
        self.assertTrue(result["read_usrsec"])

    def test_real_admin001_goes_to_usrsec(self):
        result = decide_login("ADMIN001", "PASSWORD")
        self.assertEqual(result["path"], "usrsec")
        self.assertTrue(result["read_usrsec"])

    def test_blank_user_id(self):
        result = decide_login("  ", "admin")
        self.assertEqual(result["path"], "validation")
        self.assertIn("User ID", result["message"])
        self.assertFalse(result["read_usrsec"])

    def test_blank_password(self):
        result = decide_login("admin", "")
        self.assertEqual(result["path"], "validation")
        self.assertIn("Password", result["message"])
        self.assertFalse(result["read_usrsec"])


class TestCosgn00cSourceContainsMock(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = COSGN00C.read_text(encoding="utf-8")

    def test_source_exists(self):
        self.assertTrue(COSGN00C.is_file(), f"Fonte ausente: {COSGN00C}")

    def test_mock_condition_present(self):
        self.assertRegex(
            self.source,
            r"WS-USER-ID\s*=\s*'ADMIN'",
            "Condicao de usuario mock ausente em COSGN00C",
        )
        self.assertRegex(
            self.source,
            r"WS-USER-PWD\s*=\s*'ADMIN'",
            "Condicao de senha mock ausente em COSGN00C",
        )

    def test_mock_sets_admin_type_and_xctl(self):
        self.assertIn("MOVE 'A'          TO CDEMO-USER-TYPE", self.source)
        self.assertIn("PROGRAM ('COADM01C')", self.source)

    def test_mock_precedes_usrsec_read(self):
        mock_pos = self.source.find("WS-USER-ID = 'ADMIN'")
        read_pos = self.source.find("PERFORM READ-USER-SEC-FILE")
        self.assertGreater(mock_pos, 0)
        self.assertGreater(read_pos, mock_pos)
        # O PERFORM do fluxo real deve estar no ELSE do mock
        else_block = self.source[mock_pos:read_pos]
        self.assertIn("ELSE", else_block)

    def test_empty_field_validation_still_present(self):
        self.assertIn("Please enter User ID ...", self.source)
        self.assertIn("Please enter Password ...", self.source)

    def test_usrsec_read_routine_intact(self):
        self.assertIsNotNone(
            re.search(r"READ-USER-SEC-FILE\.\s*\n\s*\n\s*EXEC CICS READ", self.source)
        )
        self.assertIn("DATASET   (WS-USRSEC-FILE)", self.source)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
