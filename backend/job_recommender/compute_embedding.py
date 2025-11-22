# compute_embedding.py
import sys
import json
from sentence_transformers import SentenceTransformer

# Load model once
model = SentenceTransformer('all-MiniLM-L6-v2')

# Get job text from Node.js
job_text = sys.argv[1]

# Compute embedding
embedding = model.encode([job_text])[0].tolist()

# Output JSON to Node.js
print(json.dumps(embedding))
