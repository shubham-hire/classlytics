#!/bin/bash

# ============================================================
# Classlytics Backend Health Check Suite
# Run with: chmod +x test_backend.sh && ./test_backend.sh
# Ensure backend is running (npm run start) before testing.
# ============================================================

BASE_URL="http://localhost:3000"
STU_ID="STU001"
TCH_ID="uid-teacher-001"
CLASS_ID="cls-10a"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

section() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }

check() {
  local label=$1
  local path=$2
  local method=${3:-GET}
  local data=$4
  local expected=${5:-200}

  printf "  %-45s" "• $label"

  if [ "$method" == "POST" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      -H "Content-Type: application/json" -d "$data" "$BASE_URL$path")
  elif [ "$method" == "PUT" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
      -H "Content-Type: application/json" -d "$data" "$BASE_URL$path")
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$path")
  fi

  if [ "$code" == "$expected" ] || ([ "$expected" == "200" ] && [ "$code" == "201" ]); then
    echo -e "${GREEN}✓ PASS  (HTTP $code)${NC}"
    ((PASS++))
  else
    echo -e "${RED}✗ FAIL  (HTTP $code, expected $expected)${NC}"
    ((FAIL++))
  fi
}

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║    Classlytics API Health Check Suite v1.0       ║"
echo "╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Base URL : $BASE_URL"
echo "  Seeded Student : $STU_ID  |  Teacher : $TCH_ID"
echo "(Run 'node seed.js --clean' first if tests are failing)"

# ── 1. CORE ──────────────────────────────────────────────────
section "1. Core Connectivity"
check "Server is up"                        "/"

# ── 2. AUTH ──────────────────────────────────────────────────
section "2. Auth"
check "Student Login"                       "/auth/login"      "POST" '{"email":"student@test.com","password":"password123"}' "200"
check "Teacher Login"                       "/auth/login"      "POST" '{"email":"teacher@test.com","password":"password123"}' "200"
check "Invalid Login (expect 401)"         "/auth/login"      "POST" '{"email":"wrong@test.com","password":"nope"}' "401"

# ── 3. TEACHER ───────────────────────────────────────────────
section "3. Teacher Module"
check "Teacher Dashboard (live stats)"     "/teacher/dashboard?teacherId=$TCH_ID"
check "Teacher Class List"                 "/teacher/classes?teacherId=$TCH_ID"
check "Teacher Profile"                    "/teacher/profile?teacherId=$TCH_ID"
check "Teacher Class Stats"                "/teacher/class-stats?teacherId=$TCH_ID"

# ── 4. STUDENT ───────────────────────────────────────────────
section "4. Student Module"
check "Student Profile"                    "/class/student/$STU_ID"
check "Students by Class"                  "/class/$CLASS_ID/students"
check "Registered Students List"           "/class/registered"
check "Behavior Logs"                      "/student/$STU_ID/behavior"

# ── 5. ASSIGNMENTS ───────────────────────────────────────────
section "5. Assignments"
check "Student Assignments (with status)" "/assignments/student/$STU_ID"
check "Class Assignments"                  "/assignments/$CLASS_ID"

# ── 6. ATTENDANCE ────────────────────────────────────────────
section "6. Attendance"
check "Student Attendance"                 "/attendance/$STU_ID"
check "Class Attendance Summary"           "/attendance/class/$CLASS_ID"

# ── 7. MARKS ─────────────────────────────────────────────────
section "7. Marks & Results"
check "Full Marks History"                 "/marks/$STU_ID"
check "Quiz Results by Subject"            "/marks/$STU_ID/quiz-results"
check "Marks by Subject (Maths)"          "/marks/$STU_ID/subject/Mathematics"

# ── 8. FEES ──────────────────────────────────────────────────
section "8. Fee Status"
check "Fee Status"                         "/fee/$STU_ID"
check "Fee Status (unpaid student)"        "/fee/STU004"

# ── 9. AI ────────────────────────────────────────────────────
section "9. AI & Insights (NVIDIA Llama 3.1)"
check "Smart Insights"                     "/ai/$STU_ID/insights"
check "Risk Assessment"                    "/ai/$STU_ID/risk"
check "Study Suggestions"                  "/ai/$STU_ID/suggestions"
check "Study Plan"                         "/ai/$STU_ID/study-plan"
check "Notifications"                      "/ai/$STU_ID/notifications"
check "AI Homework Help"                   "/ai/homework-help" "POST" '{"query":"How do molecules form?"}'

# ── 10. COMMUNICATION ────────────────────────────────────────
section "10. Communication"
check "Teacher → Student Messages"         "/communication/messages/uid-student-001"
check "Student Announcements"              "/communication/announcements/student/$STU_ID"
check "Class Announcements"                "/communication/announcements/$CLASS_ID"

# ── 11. GEO ──────────────────────────────────────────────────
section "11. Geo Data"
check "States List"                        "/geo/states"
check "Cities in Maharashtra"              "/geo/cities/MH"

# ── RESULTS ──────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Results: ${GREEN}$PASS passed${NC}${BOLD}, ${RED}$FAIL failed${NC}${BOLD} out of $TOTAL total  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"

if [ $FAIL -eq 0 ]; then
  echo -e "\n  ${GREEN}${BOLD}✅ All tests passed! Backend is healthy.${NC}\n"
else
  echo -e "\n  ${YELLOW}${BOLD}⚠️  $FAIL test(s) failed. Check server logs for details.${NC}"
  echo -e "  ${YELLOW}Tip: Run 'node seed.js --clean' to reset test data.${NC}\n"
fi
