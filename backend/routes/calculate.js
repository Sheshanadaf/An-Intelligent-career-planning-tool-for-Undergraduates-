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

    if (!jobPostId || !weights) {
      return res.status(400).json({ message: "jobPostId and weights are required" });
    }

    // 1️⃣ Fetch job post
    const jobPost = await JobPost.findById(jobPostId).populate("appliedUsers");
    if (!jobPost) {
      return res.status(404).json({ message: "Job post not found" });
    }

    const appliedUserIds = jobPost.appliedUsers.map(u => u._id);

    // 2️⃣ Fetch student profiles
    const profiles = await StudentProfile.find({ userId: { $in: appliedUserIds } });

    // 3️⃣ Fetch university rankings
    const uniRankings = await UniversityRanking.find();
    const maxRank = Math.max(...uniRankings.map(u => u.rank));

    const results = [];

    for (const profile of profiles) {
      const numProjects = profile.projects.length;
      const numLicenses = profile.licenses.length;

      // ---------------------------------------------
      // ⭐ NEW LOGIC: PROJECT SCORES (Ignore zero marks)
      // ---------------------------------------------
      let projectMarks = [];

      for (const p of profile.projects) {
        const markEntry = p.marks.find(
          m => m.jobPostId && m.jobPostId.toString() === jobPostId
        );

        if (markEntry && markEntry.value > 0) {
          projectMarks.push(markEntry.value);
        }
      }

      let avgProject = 0;
      if (projectMarks.length > 0) {
        const sum = projectMarks.reduce((a, b) => a + b, 0);
        avgProject = (sum / (100 * projectMarks.length));  // normalized
      }

      // Final P score
      const P = avgProject * (weights["projects"] || 0);
      console.log('p score',P,'avgProject',avgProject);

      // ---------------------------------------------
      // ⭐ NEW LOGIC: LICENSE SCORES (Ignore zero marks)
      // ---------------------------------------------
      let licenseMarks = [];

      for (const l of profile.licenses) {
        const markEntry = l.marks.find(
          m => m.jobPostId && m.jobPostId.toString() === jobPostId
        );

        if (markEntry && markEntry.value > 0) {
          licenseMarks.push(markEntry.value);
        }
      }

      let avgLicense = 0;
      if (licenseMarks.length > 0) {
        const sum = licenseMarks.reduce((a, b) => a + b, 0);
        avgLicense = (sum / (100 * licenseMarks.length));  // normalized
      }

      // Final B score
      const B = avgLicense * (weights["certifications"] || 0);
      console.log('B score',P,'avgLicense',avgLicense);

      // ---------------------------------------------
      // University Rank Score R
      // ---------------------------------------------
      const uniName = profile.education[0]?.school || profile.university;
      const uni = uniRankings.find(u => u.name === uniName);
      const uniRank = uni ? uni.rank : maxRank;

      const R = ((maxRank - uniRank) / (maxRank - 1)) * (weights["university"] || 0);

      // ---------------------------------------------
      // Degree class score C
      // ---------------------------------------------
      const gpa = profile.education[0]?.gpa || 0;
      const C = calculateClassScore(gpa) * (weights["gpa"] || 0);

      // ---------------------------------------------
      // Total score
      // ---------------------------------------------
      const totalScore = R + C + B + P;
      console.log("totalScore",totalScore,"R",R,"C",C,"B",B,"P",P);

      results.push({
        userId: profile.userId,
        name: profile.name,
        score: parseFloat(totalScore.toFixed(2)),
        projects: numProjects,
        university: uniName || "",
        year: profile.education[0]?.year || 0,
      });
    }

    res.status(200).json(results);

  } catch (err) {
    console.error("❌ Server Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
