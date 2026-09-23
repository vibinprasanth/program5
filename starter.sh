#!/bin/bash

# ============================================================
# Linux Security Assignment
# Secure Departmental Directory
# ============================================================

set -e

# -----------------------------
# Configuration
# -----------------------------

GROUP_NAME="students"

USER1="student1"
USER2="student2"
UNAUTHORIZED="unauthorized"

BASE_DIR="/opt/department"
STUDENT_DIR="/opt/department/students"
TEST_FILE="/opt/department/students/student_info.txt"

SELINUX_TYPE="httpd_sys_content_t"
SELINUX_BOOLEAN="httpd_read_user_content"

echo "======================================"
echo " Linux Security Assignment"
echo "======================================"

# ------------------------------------------------------------
# TODO 1: Check that the script is running as root
# ------------------------------------------------------------

echo "[1] Checking root privileges..."

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# TODO 2: Check SELinux status
# ------------------------------------------------------------

echo "[2] Checking SELinux..."

SELINUX_STATUS=$(getenforce)

if [ "$SELINUX_STATUS" != "Enforcing" ]; then
    echo "Error: SELinux must be enabled and enforcing."
    echo "Current status: $SELINUX_STATUS"
    exit 1
fi

echo "SELinux is Enforcing."

# ------------------------------------------------------------
# TODO 3: Create the students group
# ------------------------------------------------------------

echo "[3] Creating group: ${GROUP_NAME}"

if ! getent group "${GROUP_NAME}" > /dev/null; then
    groupadd "${GROUP_NAME}"
fi

# ------------------------------------------------------------
# TODO 4: Create users
# ------------------------------------------------------------

echo "[4] Creating users..."

if ! id "${USER1}" > /dev/null 2>&1; then
    useradd -m "${USER1}"
fi

if ! id "${USER2}" > /dev/null 2>&1; then
    useradd -m "${USER2}"
fi

if ! id "${UNAUTHORIZED}" > /dev/null 2>&1; then
    useradd -m "${UNAUTHORIZED}"
fi

# Add student users to students group
usermod -aG "${GROUP_NAME}" "${USER1}"
usermod -aG "${GROUP_NAME}" "${USER2}"

# Make sure unauthorized is NOT a member of students
gpasswd -d "${UNAUTHORIZED}" "${GROUP_NAME}" 2>/dev/null || true

# ------------------------------------------------------------
# TODO 5: Create departmental directory
# ------------------------------------------------------------

echo "[5] Creating directory..."

mkdir -p "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 6: Configure ownership and permissions
# ------------------------------------------------------------

echo "[6] Configuring ownership and permissions..."

# Root owns the directory; students is the group
chown root:"${GROUP_NAME}" "${BASE_DIR}"
chown root:"${GROUP_NAME}" "${STUDENT_DIR}"

# SGID + group read/write/execute
# Only owner and students group can access
chmod 2770 "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 7: Create test file
# ------------------------------------------------------------

echo "[7] Creating test file..."

echo "Departmental student information." > "${TEST_FILE}"

chown root:"${GROUP_NAME}" "${TEST_FILE}"
chmod 660 "${TEST_FILE}"

# ------------------------------------------------------------
# TODO 8: Configure persistent SELinux file context
# ------------------------------------------------------------

echo "[8] Configuring SELinux file context..."

if ! command -v semanage > /dev/null 2>&1; then
    echo "Error: semanage is required."
    echo "Install the SELinux management tools and run the script again."
    exit 1
fi

# Add persistent SELinux file-context rule
semanage fcontext -a -t "${SELINUX_TYPE}" "${STUDENT_DIR}(/.*)?"

# Apply the context
restorecon -Rv "${STUDENT_DIR}"

# ------------------------------------------------------------
# TODO 9: Configure SELinux boolean
# ------------------------------------------------------------

echo "[9] Configuring SELinux boolean..."

setsebool -P "${SELINUX_BOOLEAN}" on

# ------------------------------------------------------------
# TODO 10: Verification
# ------------------------------------------------------------

echo "[10] Verification"

echo
echo "Users:"
id "${USER1}" || true
id "${USER2}" || true
id "${UNAUTHORIZED}" || true

echo
echo "Directory:"
ls -ld "${STUDENT_DIR}" || true

echo
echo "Test file:"
ls -l "${TEST_FILE}" || true

echo
echo "SELinux context:"
ls -Zd "${STUDENT_DIR}" || true

echo
echo "SELinux status:"
getenforce || true

echo
echo "Selected SELinux boolean:"
getsebool "${SELINUX_BOOLEAN}" || true

echo
echo "======================================"
echo " Script completed"
echo "======================================"
