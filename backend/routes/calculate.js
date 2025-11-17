const express = require("express");
const router = express.Router();
const JobPost = require("../models/JobPost");
const StudentProfile = require("../models/StudentProfile");
const UniversityRanking = require("../models/UniversityRanking");

// Helper to map GPA to class score
function calculateClassScore(gpa) {
  if (gpa >= 3.7) return 1; // 1st class
  if (gpa >= 3.3) return 0.75; // 2:1
  if (gpa >= 3.0) return 0.5; // 2:2
  if (gpa >= 2.0) return 0.25; // pass
  return 0; // fail
}

router.post("/", async (req, res) => {
  try {
    const { jobPostId, weights } = req.body;

    console.log("📌 student/api/scalculate called");
    console.log("JobPostId:", jobPostId);
    console.log("Weights:", weights);


    if (!jobPostId || !weights) {
      console.log("❌ Missing jobPostId or weights");
      return res.status(400).json({ message: "jobPostId and weights are required" });
    }

    // 1️⃣ Fetch the job post
    const jobPost = await JobPost.findById(jobPostId).populate("appliedUsers");
    if (!jobPost) {
      console.log("❌ Job post not found for ID:", jobPostId);
      return res.status(404).json({ message: "Job post not found" });
    }

    console.log("✅ Job post found:", jobPost.jobRole);
    const appliedUserIds = jobPost.appliedUsers.map(u => u._id);
    console.log("Applied Users IDs:", appliedUserIds);

    // 2️⃣ Fetch student profiles for applied users
    const profiles = await StudentProfile.find({ userId: { $in: appliedUserIds } });
    console.log("✅ Fetched student profiles:", profiles.length);

    // 3️⃣ Fetch all university rankings
    const uniRankings = await UniversityRanking.find();
    const maxRank = Math.max(...uniRankings.map(u => u.rank));
    console.log("✅ University rankings fetched. Max Rank:", maxRank);

    const results = [];

    for (const profile of profiles) {
      console.log("➡ Processing profile:", profile.name);

      const numProjects = profile.projects.length;
      const numLicenses = profile.licenses.length;

      // 3a️⃣ Average project marksl
      let avgProject = 0;
      if (numProjects > 0) {
        const totalProjectMarks = profile.projects.reduce((acc, p) => {
            const markEntry = p.marks.find(m => m.jobPostId && m.jobPostId.toString() === jobPostId);
            return acc + (markEntry ? markEntry.value : 0);
            }, 0);
        avgProject = totalProjectMarks / numProjects;
      }
      console.log("Avg Project Marks:", avgProject);

      // 3b️⃣ Average license marks
      let avgLicense = 0;
      if (numLicenses > 0) {
        const totalLicenseMarks = profile.licenses.reduce((acc, l) => {
            const markEntry = l.marks.find(m => m.jobPostId && m.jobPostId.toString() === jobPostId);
            return acc + (markEntry ? markEntry.value : 0);
            }, 0);
        avgLicense = totalLicenseMarks / numLicenses;
      }
      console.log("Avg License Marks:", avgLicense);


      // 4️⃣ University rank score R
      const uniName = profile.education[0]?.school || profile.university;
      const uni = uniRankings.find(u => u.name === uniName);
      const uniRank = uni ? uni.rank : maxRank; // if not found, assign worst rank
      const R = ((maxRank - uniRank) / (maxRank - 1)) * (weights['university']|| 0);
      console.log("University Rank:", uniRank, "R Score:", R);

      // 5️⃣ Degree class score C
      const gpa = profile.education[0]?.gpa || 0;
      const C = calculateClassScore(gpa) * (weights['gpa'] || 0);
      console.log("GPA:", gpa, "C Score:", C);

      // 6️⃣ License score B
      const B = (avgLicense / 100) * (weights['certifications'] || 0);
      console.log("B Score:", B);

      // 7️⃣ Project score P
      const P = (avgProject / 100) * (weights['projects'] || 0);
      console.log("P Score:", P);

      const totalScore = R + C + B + P;
      console.log("Total Score:", totalScore.toFixed(2));

      results.push({
        userId: profile.userId,
        name: profile.name,
        score: parseFloat(totalScore.toFixed(2)),
        projects: numProjects,
        university: uniName || "",
        year: profile.education[0]?.year || 0,
      });
    }

    console.log("✅ Final Results:", results);

    res.status(200).json(results);

  } catch (err) {
    console.error("❌ Server Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
