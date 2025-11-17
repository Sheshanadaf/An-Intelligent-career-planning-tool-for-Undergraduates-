const mongoose = require("mongoose");

const EducationSchema = new mongoose.Schema({
  school: { type: String, required: true },
  degree: { type: String, required: true },
  field: { type: String, required: true },
  gpa: { type: Number, required: true },
  description: { type: String, default: "" },
  year: { type: Number, default: 0 },
  startMonth: { type: String, default: "" },
  startYear: { type: String, default: "" },
  endMonth: { type: String, default: "" },
  endYear: { type: String, default: "" },
});

const LicenseSchema = new mongoose.Schema({
  name: { type: String, required: true },
  organization: { type: String, required: true },
  issueDate: { type: String, default: "" },
  expirationDate: { type: String, default: "" },
  credentialId: { type: String },
  credentialUrl: { type: String },
  marks: [
    {
      jobPostId: { type: mongoose.Schema.Types.ObjectId, ref: "JobPost" },
      value: { type: Number, default: 0 },
    }
  ],
});


const ProjectSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String },
  projectUrl: { type: String },
  startDate: { type: String, default: "" },
  endDate: { type: String, default: "" },
  marks: [
    {
      jobPostId: { type: mongoose.Schema.Types.ObjectId, ref: "JobPost" },
      value: { type: Number, default: 0 },
    }
  ],
});

const VolunteeringSchema = new mongoose.Schema({
  organization: { type: String, required: true },
  role: { type: String, required: true },
  cause: { type: String },
  startDate: { type: String, default: "" },
  endDate: { type: String, default: "" },
  description: { type: String },
  url: { type: String },
});

const StudentProfileSchema = new mongoose.Schema(
  {
    name: { type: String, default: "" },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    bio: { type: String, default: "" },
    location: { type: String, default: "" },
    imageUrl: { type: String, default: "" },
    education: [EducationSchema],
    skills: [String],
    licenses: [LicenseSchema],
    projects: [ProjectSchema],
    volunteering: [VolunteeringSchema],

    // 🟢 NEW FIELD: Saved Job Posts
    jobPosts: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "JobPost", // reference to JobPost collection
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model("StudentProfile", StudentProfileSchema);
