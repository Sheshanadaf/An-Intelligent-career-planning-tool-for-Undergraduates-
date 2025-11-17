// models/UniversityRanking.js
const mongoose = require("mongoose");

const UniversityRankingSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true, // prevent duplicate university names
      trim: true,
    },
    rank: {
      type: Number,
      required: true,
      min: 1,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("UniversityRanking", UniversityRankingSchema);
