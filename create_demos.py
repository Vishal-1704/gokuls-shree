import os
import sys
import json
import requests
from dotenv import load_dotenv

# Load env from dart_backend
load_dotenv(os.path.join("dart_backend", ".env"))

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
API_BASE = "http://localhost:8080/api/v1"

print(f"Using API: {API_BASE}")

# 1. Create Super Admin directly in Supabase (No API route exists for this)
print("\n--- 1. Creating Super Admin (Directly via Supabase) ---")
headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

# Create user in Auth
auth_payload = {
    "email": "superadmin@demo.com",
    "password": "Password123!",
    "email_confirm": True,
    "user_metadata": {"name": "Demo Super Admin"}
}
res = requests.post(f"{SUPABASE_URL}/auth/v1/admin/users", headers=headers, json=auth_payload)
if res.status_code >= 400:
    print("Error creating superadmin in Auth:", res.text)
    # Could already exist, let's try to get it
else:
    auth_uid = res.json()["id"]
    print(f"Created Auth User: {auth_uid}")
    
    # Create profile
    profile_payload = {
        "auth_uid": auth_uid,
        "full_name": "Demo Super Admin",
        "role": "super_admin",
        "status": 1,
        "email": "superadmin@demo.com",
        "permissions": [
            "ACCESS_ALL_DATA", "READ_ALL_BRANCHES", "MANAGE_BRANCHES",
            "REGISTER_BRANCH_ADMIN", "SETUP_OWN_BRANCH", "RESET_USER_PASSWORD",
            "APPROVE_STUDENT", "APPROVE_CERTIFICATE", "REGISTER_TEACHER"
        ]
    }
    # Upsert using POST and Prefer header
    headers["Prefer"] = "resolution=merge-duplicates"
    res = requests.post(f"{SUPABASE_URL}/rest/v1/profiles", headers=headers, json=profile_payload)
    if res.status_code >= 400:
        print("Error creating superadmin profile:", res.text)
    else:
        print("Created Super Admin Profile!")

# 2. Login as Super Admin via API
print("\n--- 2. Logging in as Super Admin via API ---")
res = requests.post(f"{API_BASE}/auth/login", json={
    "email": "superadmin@demo.com",
    "password": "Password123!"
})
if res.status_code != 200:
    print("Failed to login as superadmin:", res.text)
    sys.exit(1)

token = res.json()["token"]
print("Logged in successfully. Got Token.")

auth_headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# Ensure there is a branch
print("\n--- Creating/Ensuring a Branch exists ---")
# API route: POST /branches (Super Admin only)
branch_payload = {
    "name": "Demo Main Branch",
    "location": "Demo City",
    "contact": "1234567890",
    "status": 1
}
res = requests.post(f"{API_BASE}/branches", headers=auth_headers, json=branch_payload)
branch_id = None
if res.status_code == 200:
    branch_id = res.json()["branch"]["id"]
    print(f"Created branch: {branch_id}")
else:
    print("Error creating branch (maybe exists):", res.text)
    # Try fetching branches
    res = requests.get(f"{API_BASE}/branches", headers=auth_headers)
    if res.status_code == 200 and len(res.json().get("branches", [])) > 0:
        branch_id = res.json()["branches"][0]["id"]
        print(f"Using existing branch: {branch_id}")

# 3. Create Branch Admin via API
print("\n--- 3. Creating Branch Admin via API ---")
res = requests.post(f"{API_BASE}/auth/admin/register-branch-admin", headers=auth_headers, json={
    "name": "Demo Branch Admin",
    "email": "branchadmin@demo.com",
    "password": "Password123!"
})
print("Branch Admin Res:", res.status_code, res.text)

# We need to assign branch admin to the branch so they can create teachers for that branch
# But the register-branch-admin endpoint doesn't accept branch_id in our current code, they set it up themselves later.
# Actually, the super admin can update the profile to assign a branch_id using Supabase directly, or via branches endpoint.

# 4. Create Teacher via API
print("\n--- 4. Creating Teacher via API ---")
res = requests.post(f"{API_BASE}/auth/admin/register-teacher", headers=auth_headers, json={
    "name": "Demo Teacher",
    "email": "teacher@demo.com",
    "password": "Password123!",
    "branch_id": branch_id
})
print("Teacher Res:", res.status_code, res.text)

# 5. Create Student via Public API
print("\n--- 5. Creating Student via Public API ---")
res = requests.post(f"{API_BASE}/auth/register", json={
    "name": "Demo Student",
    "email": "student@demo.com",
    "password": "Password123!",
    "phone": "9876543210",
    "father_name": "Demo Father",
    "dob": "2000-01-01",
    "address": "Demo Address",
    "gender": "Male",
    "branch_id": branch_id
})
print("Student Res:", res.status_code, res.text)

print("\n--- All Done! ---")
print("Credentials created:")
print("- superadmin@demo.com / Password123!")
print("- branchadmin@demo.com / Password123!")
print("- teacher@demo.com / Password123!")
print("- student@demo.com / Password123!")
