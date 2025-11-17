const mongoose = require("mongoose");

const companyProfileSchema = new mongoose.Schema(
  {
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      unique: true,
      required: true,
    },
    companyName: { type: String, required: true },
    email: { type: String, required: true },
    companyReg: { type: String },
    password: { type: String },
    role: { type: String, default: "company" },
    companyLogo: { type: String },
  },
  { timestamps: true } // 🕒 Adds createdAt & updatedAt automatically
);

// ✅ Export model
module.exports = mongoose.model("CompanyProfile", companyProfileSchema);
