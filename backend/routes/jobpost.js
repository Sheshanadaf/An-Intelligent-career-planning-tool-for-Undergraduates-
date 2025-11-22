const express = require("express");
const JobPost = require("../models/JobPost");
const StudentProfile = require("../models/StudentProfile");
const { spawn } = require('child_process');
const path = require("path");

const router = express.Router();


// 🟠 Remove a job post from a student's saved jobs
router.delete("/remove", async (req, res) => {
  try {
    const { userId, jobPostId } = req.body;
    console.log("🗑️ Request to remove job:", { userId, jobPostId });

    if (!userId || !jobPostId) {
      return res.status(400).json({ message: "Missing userId or jobPostId" });
    }

    // ✅ Find the student's profile
    const studentProfile = await StudentProfile.findOne({ userId });
    if (!studentProfile) {
      return res.status(404).json({ message: "Student profile not found" });
    }

    // ✅ Remove the jobPostId from student's jobPosts array
    const index = studentProfile.jobPosts.indexOf(jobPostId);
    if (index === -1) {
      return res.status(404).json({ message: "Job not found in user's list" });
    }

    studentProfile.jobPosts.splice(index, 1);
    await studentProfile.save();
    console.log("✅ Job removed from student profile");

    // ✅ Find the job post and remove userId from appliedUsers array
    const jobPost = await JobPost.findById(jobPostId);
    if (jobPost) {
      const userIndex = jobPost.appliedUsers.indexOf(userId);
      if (userIndex !== -1) {
        jobPost.appliedUsers.splice(userIndex, 1);
        await jobPost.save();
        console.log("✅ User removed from jobPost.appliedUsers");
      } else {
        console.log("⚠️ User was not listed in jobPost.appliedUsers");
      }
    } else {
      console.log("⚠️ Job post not found in database");
    }

    // ✅ Response
    res.status(200).json({
      message: "✅ Job removed successfully from both student and job post",
      studentProfile,
    });

  } catch (error) {
    console.error("❌ Error removing job:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


// 🟢 Get all job posts related to a student
router.get("/jobs/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`📥 Fetching job posts for student userId: ${userId}`);

    // Find student profile
    const profile = await StudentProfile.findOne({ userId });

    if (!profile) {
      return res.status(404).json({ message: "Student profile not found" });
    }

    // Fetch job posts details from IDs
    const jobPosts = await JobPost.find({
      _id: { $in: profile.jobPosts },
    }).sort({ createdAt: -1 });

    console.log(`📦 Found ${jobPosts.length} job posts for user ${userId}`);
    res.status(200).json({ jobPosts });
  } catch (error) {
    console.error("❌ Error fetching student's job posts:", error);
    res.status(500).json({ message: "Server error", error });
  }
});

// 🟢 Add a job post to a student's saved jobs and add user to job post
router.put("/", async (req, res) => {
  try {
    const { userId, jobPostId } = req.body;

    console.log("📩 Incoming request to add job to student profile:");
    console.log("➡️ userId:", userId);
    console.log("➡️ jobPostId:", jobPostId);

    if (!userId || !jobPostId) {
      return res.status(400).json({ message: "Missing userId or jobPostId" });
    }

    // ✅ Find student profile
    const studentProfile = await StudentProfile.findOne({ userId });
    if (!studentProfile) {
      console.log("❌ Student profile not found");
      return res.status(404).json({ message: "Student profile not found" });
    }

    // ✅ Add jobPostId to studentProfile (avoid duplicates)
    if (!studentProfile.jobPosts.includes(jobPostId)) {
      studentProfile.jobPosts.push(jobPostId);
      await studentProfile.save();
      console.log("✅ Job post added to student profile");
    } else {
      console.log("⚠️ Job already exists in student profile");
    }

    // ✅ Find the job post and add userId to appliedUsers (avoid duplicates)
    const jobPost = await JobPost.findById(jobPostId);
    if (!jobPost) {
      console.log("❌ Job post not found");
      return res.status(404).json({ message: "Job post not found" });
    }

    if (!jobPost.appliedUsers.includes(userId)) {
      jobPost.appliedUsers.push(userId);
      await jobPost.save();
      console.log("✅ Student added to jobPost.appliedUsers");
    } else {
      console.log("⚠️ Student already added to jobPost.appliedUsers");
    }

    res.status(200).json({
      message: "✅ Job successfully linked between student and job post",
      studentProfile,
      jobPost,
    });
  } catch (error) {
    console.error("❌ Error adding job to student profile:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


// 🟡 Optional: Get all saved jobs for a student (populated)
router.get("/:userId/jobs", async (req, res) => {
  try {
    const { userId } = req.params;
    console.log("📦 Fetching saved jobs for userId:", userId);

    const profile = await StudentProfile.findOne({ userId }).populate("jobPosts");

    if (!profile) {
      console.log("❌ Student profile not found");
      return res.status(404).json({ message: "Student profile not found" });
    }

    console.log("✅ Jobs fetched successfully");
    res.status(200).json({ jobPosts: profile.jobPosts });
  } catch (error) {
    console.error("❌ Error fetching saved jobs:", error);
    res.status(500).json({ message: "Server error", error });
  }
});

// 🟢 Delete a job post by ID
router.delete("/:postId", async (req, res) => {
  try {
    const { postId } = req.params;

    console.log("🗑️ Incoming Delete Request for Job Post ID:", postId);

    if (!postId) {
      return res.status(400).json({ message: "Post ID is required" });
    }

    const deletedPost = await JobPost.findByIdAndDelete(postId);

    if (!deletedPost) {
      return res.status(404).json({ message: "Job post not found" });
    }

    res.status(200).json({
      message: "Job post deleted successfully",
      jobPost: deletedPost,
    });
  } catch (error) {
    console.error("❌ Error deleting job post:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


router.post("/", async (req, res) => {
  try {
    const { companyId, companyName, companyReg, jobRole, description, skills, certifications, details, weights, companyLogo } = req.body;

    if (!companyId || !companyName || !jobRole) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Step 1: create job without embedding first
    const newJobPost = new JobPost({
      companyId, companyName, companyReg, jobRole, description, skills, certifications, details, weights, companyLogo
    });

    await newJobPost.save();

    // Step 2: prepare text for embedding
    const jobText = `${jobRole}. ${description}. ${skills}. ${certifications}`;

    // Step 3: call Python script
    const py = spawn("C:\\fyp\\backend\\job_recommender\\venv\\Scripts\\python.exe", ["compute_embedding.py", jobText]);


    py.stdout.on('data', async (data) => {
      const embedding = JSON.parse(data.toString());

      // Step 4: update job with embedding
      await JobPost.findByIdAndUpdate(newJobPost._id, { embedding });
      console.log("Embedding saved for job:", newJobPost._id);
    });

    py.stderr.on('data', (err) => {
      console.error("Python error:", err.toString());
    });

    res.status(201).json({ message: "Job post created successfully", jobPost: newJobPost });

  } catch (error) {
    console.error("❌ Error creating job post:", error);
    res.status(500).json({ message: "Server error", error });
  }
});

// 🟢 Get all job posts (for students)
router.get("/", async (req, res) => {
  try {
    console.log("📦 Fetching all job posts");
    const posts = await JobPost.find().sort({ createdAt: -1 });
    res.status(200).json(posts);
  } catch (error) {
    console.error("❌ Error fetching job posts:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


// 🟢 Get all job posts for a company
router.get("/:companyId", async (req, res) => {
  try {
    const { companyId } = req.params;
    console.log(`📦 Fetching posts for company companyId: ${companyId}`);

    const posts = await JobPost.find({ companyId }).sort({ createdAt: -1 });
    res.status(200).json({ jobPosts: posts });
  } catch (error) {
    console.error("❌ Error fetching company posts:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


// 🟡 Update an existing job post
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`✏️ Updating job post ID: ${id}`);
    console.log("📥 New Data:", req.body);

    // 1️⃣ Update the job fields
    const updatedPost = await JobPost.findByIdAndUpdate(
      id,
      {
        $set: {
          jobRole: req.body.jobRole,
          description: req.body.description,
          skills: req.body.skills,
          certifications: req.body.certifications,
          details: req.body.details,
          weights: req.body.weights,
          companyName: req.body.companyName,
          companyReg: req.body.companyReg,
        },
      },
      { new: true } // return updated document
    );

    if (!updatedPost) {
      return res.status(404).json({ message: "Job post not found" });
    }

    // 2️⃣ Prepare text for embedding
    const jobText = `${updatedPost.jobRole}. ${updatedPost.description}. ${updatedPost.skills}. ${updatedPost.certifications}`;

    // Absolute path to compute_embedding.py
    const scriptPath = path.join(__dirname, "..", "job_recommender", "compute_embedding.py");

    // Spawn Python using venv
    const py = spawn(
      "C:\\fyp\\backend\\job_recommender\\venv\\Scripts\\python.exe",
      [scriptPath, jobText]
    );

    py.stdout.on("data", async (data) => {
      try {
        const embedding = JSON.parse(data.toString());

        // 4️⃣ Update embedding in MongoDB
        await JobPost.findByIdAndUpdate(updatedPost._id, { embedding });

        console.log("✅ Embedding updated for job:", updatedPost._id);
      } catch (err) {
        console.error("❌ Error parsing embedding:", err);
      }
    });

    py.stderr.on("data", (err) => {
      console.error("❌ Python error:", err.toString());
    });

    // 5️⃣ Respond immediately (embedding updates asynchronously)
    res.status(200).json({
      message: "Job post updated successfully (embedding will update shortly)",
      jobPost: updatedPost,
    });
  } catch (error) {
    console.error("❌ Error updating job post:", error);
    res.status(500).json({ message: "Server error", error });
  }
});

// 🟢 Get top recommended jobs for a student
router.get("/recommend/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    console.log(`🔹 Fetching recommended jobs for student userId: ${userId}`);

    // Find student profile
    const studentProfile = await StudentProfile.findOne({ userId });
    if (!studentProfile) {
      return res.status(404).json({ message: "Student profile not found" });
    }

    // Absolute path to recommend_jobs.py
    const scriptPath = path.join(__dirname, "..", "job_recommender", "recommend_jobs.py");

    // Spawn Python script and pass student _id as argument
    const py = spawn(
      "C:\\fyp\\backend\\job_recommender\\venv\\Scripts\\python.exe",
      [scriptPath, studentProfile._id.toString()]
    );

    let dataString = "";

    py.stdout.on("data", (data) => {
      dataString += data.toString();
    });

    py.stderr.on("data", (err) => {
      console.error("❌ Python error:", err.toString());
    });

    py.on("close", async (code) => {
      if (code !== 0) {
        console.error(`❌ Python script exited with code ${code}`);
        return res.status(500).json({ message: "Error running recommendation script" });
      }

      try {
        const pythonResult = JSON.parse(dataString); // array of {_id, similarity, ...}

        // Extract job IDs from Python result
        const jobIds = pythonResult.map(j => j._id);

        // Fetch full job documents from MongoDB
        const jobs = await JobPost.find({ _id: { $in: jobIds } });

        // Merge similarity from Python result
        const jobsWithSimilarity = jobs.map(job => {
          const scoreObj = pythonResult.find(rj => rj._id === job._id.toString());
          return {
            ...job.toObject(), // full job data
            similarity: scoreObj ? scoreObj.similarity : 0
          };
        });

        // Optional: sort by similarity descending
        jobsWithSimilarity.sort((a, b) => b.similarity - a.similarity);

        res.status(200).json({ recommendedJobs: jobsWithSimilarity });

      } catch (err) {
        console.error("❌ Error parsing Python output:", err);
        res.status(500).json({ message: "Failed to parse recommendation result" });
      }
    });

  } catch (error) {
    console.error("❌ Error fetching recommended jobs:", error);
    res.status(500).json({ message: "Server error", error });
  }
});


module.exports = router;
