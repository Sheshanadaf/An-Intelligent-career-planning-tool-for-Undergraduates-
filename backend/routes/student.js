const express = require("express");
const router = express.Router();
const StudentProfile = require("../models/StudentProfile");
const multer = require("multer");
const path = require("path");

// === Multer Setup ===
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // save to uploads folder
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  }
});
const upload = multer({ storage });

// =========================
// PUT: Update Student Profile
// =========================
router.put("/profile/update", upload.single("image"), async (req, res) => {
  try {
    const { name, userId, bio, location, education, skills, licenses, projects, volunteering } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "User ID required" });
    }

    // Fetch existing profile
    const profile = await StudentProfile.findOne({ userId });
    if (!profile) {
      return res.status(404).json({ message: "Profile not found" });
    }

    // Parse JSON fields if needed
    const parseArrayField = (field) => {
      if (!field) return [];
      if (typeof field === "string") return JSON.parse(field);
      if (Array.isArray(field)) return field;
      return [];
    };

    // Update fields
    // Update only if value exists
    profile.name = name ?? profile.name;
    profile.bio = bio ?? profile.bio;
    profile.location = location ?? profile.location;
    profile.education = education ? parseArrayField(education) : profile.education;
    profile.skills = skills ? parseArrayField(skills) : profile.skills;
    profile.licenses = licenses ? parseArrayField(licenses) : profile.licenses;
    profile.projects = projects ? parseArrayField(projects) : profile.projects;
    profile.volunteering = volunteering ? parseArrayField(volunteering) : profile.volunteering;

    // Update image if uploaded
    if (req.file) {
      profile.imageUrl = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
    }

    await profile.save();

    res.json({ message: "Profile updated successfully", profile });

  } catch (err) {
    console.error("Error updating profile:", err);
    res.status(500).json({ message: "Failed to update profile" });
  }
});


// =========================
// POST: Create / Update Student Profile
// =========================
router.post("/profile", upload.single("image"), async (req, res) => {
  try {
    const { name, userId, bio, location,imageUrl, education, skills } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "User ID required" });
    }

    // Validate arrays
    let eduArray = [];
    if (education) {
      if (typeof education === "string") {
        eduArray = JSON.parse(education); // in case frontend sends JSON string
      } else if (Array.isArray(education)) {
        eduArray = education;
      } else {
        return res.status(400).json({ message: "Education must be an array" });
      }
    }

    let skillsArray = [];
    if (skills) {
      if (typeof skills === "string") {
        skillsArray = JSON.parse(skills); // JSON string
      } else if (Array.isArray(skills)) {
        skillsArray = skills;
      } else {
        return res.status(400).json({ message: "Skills must be an array" });
      }
    }

    const profileData = {
      name,
      userId,
      bio,
      location,
      imageUrl,
      education: eduArray,
      skills: skillsArray
    };

    // Add image URL if uploaded
    if (req.file) {
      // Full URL so Flutter NetworkImage can load it
      profileData.imageUrl = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
    }

    const profile = new StudentProfile(profileData);
    await profile.save();

    res.json({ message: "Profile saved successfully", profile });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to save profile" });
  }
});

// Add Skill
router.post("/profile/skills/add", async (req, res) => {
  const { userId, skill } = req.body;
  if (!userId || !skill) return res.status(400).json({ message: "UserId and skill required" });

  try {
    const profile = await StudentProfile.findOne({ userId });
    if (!profile) return res.status(404).json({ message: "User not found" });

    profile.skills = profile.skills || [];
    if (!profile.skills.includes(skill)) profile.skills.push(skill);

    await profile.save();
    res.json({ message: "Skill added", skills: profile.skills });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to add skill" });
  }
});

// Remove Skill
router.post("/profile/skills/remove", async (req, res) => {
  const { userId, skill } = req.body;
  if (!userId || !skill) return res.status(400).json({ message: "UserId and skill required" });

  try {
    const profile = await StudentProfile.findOne({ userId });
    if (!profile) return res.status(404).json({ message: "User not found" });

    profile.skills = (profile.skills || []).filter(s => s !== skill);

    await profile.save();
    res.json({ message: "Skill removed", skills: profile.skills });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to remove skill" });
  }
});


// =========================
// POST: Create or Update Student Profile
// =========================
router.put("/profileheader", upload.single("image"), async (req, res) => {
  try {
    const { userId, name, bio, location } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }

    // Build profile object
    const profileData = {
      userId,
      name,
      bio,
      location,
    };

    // Handle uploaded image
    if (req.file) {
      profileData.imageUrl = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
    }

    // Upsert profile: update if exists, otherwise create
    const profile = await StudentProfile.findOneAndUpdate(
      { userId },
      profileData,
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    res.status(200).json(profile);
  } catch (err) {
    console.error("❌ Error saving profile:", err);
    res.status(500).json({ message: "Failed to save profile" });
  }
});

// =========================
// PUT: Update Marks for Project / License
// =========================
router.put("/profile/marks/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { section, itemId, jobPostId, value } = req.body;
    console.log("Request body:", req.body);

    if (!userId || !section || !itemId || !jobPostId || value == null) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Fetch existing profile
    const profile = await StudentProfile.findOne({ userId });
    if (!profile) return res.status(404).json({ message: "Profile not found" });

    // Determine target array
    let targetArray;
    if (section === "license") targetArray = profile.licenses;
    else if (section === "project") targetArray = profile.projects;
    else return res.status(400).json({ message: "Invalid section type" });

    // Find the item (license/project) by ID
    const item = targetArray.find(i => i._id.toString() === itemId);
    if (!item) return res.status(404).json({ message: `${section} not found` });

    // Ensure marks array exists
    if (!Array.isArray(item.marks)) item.marks = [];

    // Convert jobPostId to string for comparison
    const jobPostIdStr = jobPostId.toString();

    // Find existing mark for this jobPostId
    const existingMark = item.marks.find(m => m.jobPostId?.toString() === jobPostIdStr);

    if (existingMark) {
      // Update existing mark
      existingMark.value = value;
    } else {
      // Add new mark object
      item.marks.push({ jobPostId, value });
    }

    // Save the profile
    await profile.save();

    res.json({ message: "Marks updated successfully", profile });
  } catch (err) {
    console.error("Error updating marks:", err);
    res.status(500).json({ message: "Failed to update marks" });
  }
});


// =========================
// GET: Fetch Student Profile
// =========================
router.get("/profile/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) return res.status(400).json({ message: "User ID required" });

    const profile = await StudentProfile.findOne({ userId });
    if (!profile) return res.status(404).json({ message: "Profile not found" });

    res.json(profile);

  } catch (err) {
    console.error("Error fetching student profile:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
