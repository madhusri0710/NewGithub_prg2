#!/bin/bash

set -e

echo "Starting Student table verification..."

mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
DROP DATABASE IF EXISTS CollegeDB;
CREATE DATABASE CollegeDB;
EOF

echo "Database created successfully."

if [ ! -f "starter/answers.sql" ]; then
    echo "ERROR: starter/answers.sql not found."
    exit 1
fi

mysql -u root -p"$MYSQL_ROOT_PASSWORD" CollegeDB < starter/answers.sql

echo "SQL file executed successfully."

TABLE_EXISTS=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -N -s CollegeDB \
    -e "SHOW TABLES LIKE 'Student';")

if [ "$TABLE_EXISTS" != "Student" ]; then
    echo "FAIL: Student table was not created."
    exit 1
fi

echo "PASS: Student table exists."

echo "Table structure:"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" CollegeDB \
    -e "DESCRIBE Student;"

echo "Checking required columns..."

mysql -u root -p"$MYSQL_ROOT_PASSWORD" CollegeDB <<EOF
SELECT StudentID, StudentName, DOB, Gender, DepartmentID
FROM Student
LIMIT 0;
EOF

echo "PASS: Required columns exist."

echo "Checking PRIMARY KEY..."

PK_COUNT=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -N -s CollegeDB -e "
SELECT COUNT(*)
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA='CollegeDB'
AND TABLE_NAME='Student'
AND CONSTRAINT_TYPE='PRIMARY KEY';
")

if [ "$PK_COUNT" -lt 1 ]; then
    echo "FAIL: PRIMARY KEY constraint missing."
    exit 1
fi

echo "PASS: PRIMARY KEY exists."

echo "Checking NOT NULL constraints..."

NULLABLE_COUNT=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -N -s CollegeDB -e "
SELECT COUNT(*)
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='CollegeDB'
AND TABLE_NAME='Student'
AND COLUMN_NAME IN ('StudentName','DOB','Gender','DepartmentID')
AND IS_NULLABLE='YES';
")

if [ "$NULLABLE_COUNT" -ne 0 ]; then
    echo "FAIL: Required NOT NULL constraints are missing."
    exit 1
fi

echo "PASS: NOT NULL constraints exist."

echo "Checking UNIQUE constraint..."

UNIQUE_COUNT=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -N -s CollegeDB -e "
SELECT COUNT(*)
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA='CollegeDB'
AND TABLE_NAME='Student'
AND CONSTRAINT_TYPE='UNIQUE';
")

if [ "$UNIQUE_COUNT" -lt 1 ]; then
    echo "FAIL: UNIQUE constraint missing."
    exit 1
fi

echo "PASS: UNIQUE constraint exists."

echo "===================================="
echo "ALL TESTS PASSED"
echo "===================================="
