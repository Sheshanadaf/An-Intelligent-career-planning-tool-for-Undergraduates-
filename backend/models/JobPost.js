const mongoose = require("mongoose");

const JobPostSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User", // assuming company users are stored in 'User' collection
    required: true,
  },
  companyName: { type: String, required: true },
  companyReg: { type: String, required: true },
  companyLogo: { type: String, required: true },
  jobRole: { type: String, required: true },
  description: { type: String, required: true },
  skills: { type: String, required: true },
  certifications: { type: String, required: true },
  details: { type: String, required: false },

  weights: {
    university: { type: Number, default: 0 },
    gpa: { type: Number, default: 0 },
    certifications: { type: Number, default: 0 },
    projects: { type: Number, default: 0 },
  },
  embedding: {
    type: [Number], // stores precomputed embedding vector
    default: []
  },
  // 🆕 store which students have added this job
  appliedUsers: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],

  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("JobPost", JobPostSchema);
