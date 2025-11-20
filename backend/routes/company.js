const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const CompanyProfile = require("../models/CompanyProfile");

// =========================
// 🔧 Multer Setup
// =========================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // Save all uploaded logos in /uploads
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  }
});

const upload = multer({ storage });

// =========================
// 📦 POST: Create Company Profile
// =========================
router.post("/profile", upload.single("companyLogo"), async (req, res) => {
  try {
    console.log("📥 Incoming /profile POST request...");

    // 🧩 Print body content line by line
    console.log("🟦 ====== REQUEST BODY ======");
    Object.entries(req.body).forEach(([key, value]) => {
      console.log(`🔹 ${key}: ${value}`);
    });

    // 🧩 Print file info (if any)
    if (req.file) {
      console.log("🟨 ====== FILE INFO ======");
      console.log(`🖼️ Field Name: ${req.file.fieldname}`);
      console.log(`📁 Original Name: ${req.file.originalname}`);
      console.log(`📄 Saved As: ${req.file.filename}`);
      console.log(`📏 Size: ${req.file.size} bytes`);
      console.log(`📂 Path: ${req.file.path}`);
    } else {
      console.log("⚪ No file uploaded with this request.");
    }

    const { companyId, companyName, email, companyReg, companyDis, role, password } = req.body;

    if (!companyId) {
      console.log("❌ Missing companyId in body!");
      return res.status(400).json({ message: "❌ User ID is required" });
    }

    // ✅ Build profile data
    const profileData = {
      companyId,
      companyName,
      email,
      companyReg,
      companyDis,
      role,
      password,
    };

    // ✅ If logo uploaded, add full URL
    if (req.file) {
      profileData.companyLogo = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
    }

    console.log("🟩 ====== PROFILE DATA TO SAVE ======");
    Object.entries(profileData).forEach(([key, value]) => {
      console.log(`✅ ${key}: ${value}`);
    });

    // ✅ Save new company profile
    const profile = new CompanyProfile(profileData);
    await profile.save();

    console.log("🎉 Company profile created successfully!");
    res.json({
      message: "🏢 Company profile created successfully",
      profile,
    });
  } catch (err) {
    console.error("❌ Error creating company profile:", err);
    res.status(500).json({ message: "Server error creating company profile" });
  }
});

// =========================
// ✏️ PUT: Update Company Profile
// =========================
router.put("/profile/update", upload.single("companyLogo"), async (req, res) => {
  try {
    console.log("📥 Incoming request to /profile/update");
    console.log("🧾 Request body:", req.body);
    console.log("🖼️ Uploaded file:", req.file);

    const { 
      companyId, 
      companyName, 
      email, 
      companyReg,
      companyDis,
      jobRole,
      description,
      skills,
      certifications,
      ddetails,
      weights
    } = req.body;

    if (!companyId) {
      console.log("❌ Validation failed: No userId provided");
      return res.status(400).json({ message: "❌ User ID required" });
    }

    console.log(`🔍 Searching for company profile with userId: ${companyId}`);
    const profile = await CompanyProfile.findOne({ companyId });

    if (!profile) {
      console.log("⚠️ Profile not found for userId:", companyId);
      return res.status(404).json({ message: "Profile not found" });
    }

    // ✅ Update profile fields if values exist
    if (companyName && companyName.trim() !== "") {
      profile.companyName = companyName.trim();
      console.log("✅ Updated companyName:", companyName);
    }

    if (email && email.trim() !== "") {
      profile.email = email.trim();
      console.log("✅ Updated email:", email);
    }

    if (companyReg && companyReg.trim() !== "") {
      profile.companyReg = companyReg.trim();
      console.log("✅ Updated companyReg:", companyReg);
    }
    if (companyDis && companyDis.trim() !== "") {
      profile.companyDis = companyDis.trim();
      console.log("✅ Updated companyDis:", companyDis);
    }

    // ✅ Update logo if file uploaded
    if (req.file) {
      profile.companyLogo = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
      console.log("🖼️ Updated companyLogo URL:", profile.companyLogo);
    }

    // ✅ Add job post if any related fields are provided
    if (jobRole || description || skills || certifications || ddetails || weights) {
      if (!profile.jobPosts) profile.jobPosts = [];
      const newJobPost = {
        jobRole: jobRole?.trim() || "",
        description: description?.trim() || "",
        skills: skills?.trim() || "",
        certifications: certifications?.trim() || "",
        ddetails: ddetails?.trim() || "",
        weights: weights ? JSON.parse(JSON.stringify(weights)) : {},
        createdAt: new Date(),
      };

      profile.jobPosts.push(newJobPost);
      console.log("🆕 Added new job post:", newJobPost);
    } else {
      console.log("ℹ️ No job post fields provided — skipping job post addition.");
    }

    console.log("💾 Saving updated profile...");
    await profile.save();
    console.log("✅ Profile saved successfully!");

    res.json({
      message: "✅ Company profile updated successfully (with job post if provided)",
      profile,
    });
  } catch (err) {
    console.error("❌ Error updating company profile:", err);
    res.status(500).json({ message: "Server error updating company profile", error: err.message });
  }
});

  // =========================
// ✏️ PUT: Update Company Profile (Simplified for frontend requests)
// =========================
// ------------------- Update Company Profile -------------------
router.put(
  "/profile/update/:companyId",
  upload.single("companyLogo"),
  async (req, res) => {
    try {
      const { companyId } = req.params;
      if (!companyId) {
        return res.status(400).json({ message: "❌ Company ID required" });
      }

      const profile = await CompanyProfile.findOne({ companyId });
      if (!profile) {
        return res.status(404).json({ message: "❌ Profile not found" });
      }

      console.log("📥 Incoming profile update request");
      console.log("🧾 Text fields:", req.body);
      console.log("🖼️ Uploaded file:", req.file);

      // Update text fields if provided
      const { companyName, companyReg, companyDis } = req.body;
      if (companyName && companyName.trim() !== "")
        profile.companyName = companyName.trim();
      if (companyReg && companyReg.trim() !== "")
        profile.companyReg = companyReg.trim();
      if (companyDis && companyDis.trim() !== "")
        profile.companyDis = companyDis.trim();

      // Update logo if file uploaded
      if (req.file) {
        profile.companyLogo = `${req.protocol}://${req.get(
          "host"
        )}/uploads/${req.file.filename}`;
      }

      await profile.save();
      console.log("✅ Profile updated successfully");

      res.status(200).json({
        message: "✅ Company profile updated successfully",
        profile,
      });
    } catch (err) {
      console.error("❌ Error updating company profile:", err);
      res.status(500).json({
        message: "Server error updating company profile",
        error: err.message,
      });
    }
  }
);
// =========================
// 📥 GET: Fetch Company Profile
// =========================
router.get("/profile/:companyId", async (req, res) => {
  try {
    const { companyId } = req.params;

    if (!companyId) {
      return res.status(400).json({ message: "User ID required" });
    }

    const profile = await CompanyProfile.findOne({ companyId });
    if (!profile) {
      return res.status(404).json({ message: "Profile not found" });
    }

    res.json(profile);
  } catch (err) {
    console.error("❌ Error fetching company profile:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
