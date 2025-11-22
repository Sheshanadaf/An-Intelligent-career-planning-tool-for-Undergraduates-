import sys
import json
from pymongo import MongoClient
from bson import ObjectId
from sentence_transformers import SentenceTransformer
import numpy as np
import re

# ----------------------------
# Helper functions
# ----------------------------
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^a-zA-Z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def student_to_text(student):
    texts = []
    texts.append("Skills: " + ", ".join(student.get("skills", [])))

    for edu in student.get("education", []):
        texts.append(f"{edu.get('degree','')} in {edu.get('field','')} from {edu.get('school','')}")

    for proj in student.get("projects", []):
        texts.append(proj.get("name", "") + " " + proj.get("description", ""))

    for lic in student.get("licenses", []):
        texts.append(lic.get("name", "") + " " + lic.get("organization", ""))

    return clean_text(". ".join(texts))

def cosine_similarity(vec1, vec2):
    return np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))

# ----------------------------
# Get student ID from command line
# ----------------------------
student_id = sys.argv[1]

# ----------------------------
# MongoDB connection
# ----------------------------
client = MongoClient("mongodb+srv://shenal:GOuc1pPiFLhjtsCS@cluster0.nzuzq9o.mongodb.net/?appName=Cluster0")
db = client["test"]

# Fetch student
student = db["studentprofiles"].find_one({"_id": ObjectId(student_id)})
if student is None:
    print(json.dumps({"error": "Student not found"}))
    sys.exit(1)

# Fetch jobs
jobs = list(db["jobposts"].find({"embedding": {"$exists": True, "$ne": []}}))
if not jobs:
    print(json.dumps({"error": "No jobs found"}))
    sys.exit(1)

# ----------------------------
# Compute student embedding
# ----------------------------
model = SentenceTransformer('all-MiniLM-L6-v2')
student_text = student_to_text(student)
student_embedding = model.encode([student_text])[0]

# ----------------------------
# Compute similarity
# ----------------------------
scores = []
for job in jobs:
    job_embedding = np.array(job['embedding'])
    similarity = cosine_similarity(student_embedding, job_embedding)
    scores.append((job, similarity))

scores.sort(key=lambda x: x[1], reverse=True)
top_jobs = scores[:10]

# ----------------------------
# Return JSON
# ----------------------------
result = []
for job, similarity in top_jobs:
    result.append({
        "_id": str(job['_id']),
        "jobRole": job['jobRole'],
        "companyName": job.get('companyName', ''),
        "similarity": similarity
    })

print(json.dumps(result))
