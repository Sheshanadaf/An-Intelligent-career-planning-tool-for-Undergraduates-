// routes/universityRankingRoutes.js
const express = require("express");
const router = express.Router();
const UniversityRanking = require("../models/UniversityRanking");

// ✅ GET all rankings
router.get("/", async (req, res) => {
  try {
    const rankings = await UniversityRanking.find().sort({ rank: 1 }); // sort by rank ascending
    res.status(200).json(rankings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ✅ POST add new ranking
router.post("/", async (req, res) => {
  try {
    const { name, rank } = req.body;

    if (!name || !rank) {
      return res.status(400).json({ message: "Name and rank are required" });
    }

    // 🔍 Check for existing university name
    const existingName = await UniversityRanking.findOne({ name: name.trim() });
    if (existingName) {
      return res.status(400).json({ message: "University name already exists" });
    }

    // 🔍 Check for existing rank
    const existingRank = await UniversityRanking.findOne({ rank });
    if (existingRank) {
      return res.status(400).json({
        message: `Rank ${rank} is already assigned to ${existingRank.name}`,
      });
    }

    const newUni = new UniversityRanking({ name: name.trim(), rank });
    await newUni.save();

    res.status(201).json(newUni);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ✅ PUT update existing ranking
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, rank } = req.body;

    const existing = await UniversityRanking.findById(id);
    if (!existing) {
      return res.status(404).json({ message: "University not found" });
    }

    // 🔍 Check for duplicate university name (excluding itself)
    const duplicateName = await UniversityRanking.findOne({
      name: name.trim(),
      _id: { $ne: id },
    });
    if (duplicateName) {
      return res.status(400).json({ message: "Another university already uses this name" });
    }

    // 🔍 Check for duplicate rank (excluding itself)
    const duplicateRank = await UniversityRanking.findOne({
      rank,
      _id: { $ne: id },
    });
    if (duplicateRank) {
      return res.status(400).json({
        message: `Rank ${rank} is already assigned to ${duplicateRank.name}`,
      });
    }

    const updated = await UniversityRanking.findByIdAndUpdate(
      id,
      { name: name.trim(), rank },
      { new: true, runValidators: true }
    );

    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ✅ DELETE a university
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await UniversityRanking.findByIdAndDelete(id);

    if (!deleted) return res.status(404).json({ message: "University not found" });

    res.status(200).json({ message: "University deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
