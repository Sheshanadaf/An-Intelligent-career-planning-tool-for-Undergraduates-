// index.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/student');
const companyRoutes = require('./routes/company');
const jobPostRoutes = require('./routes/jobpost');
const uniRankRoutes = require('./routes/universityRanking');
const calculateRoutes = require('./routes/calculate');

const path = require('path');



const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
// Serve static files in uploads folder
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/company', companyRoutes);
app.use('/api/jobpost', jobPostRoutes);
app.use('/api/university-rankings', uniRankRoutes);
app.use('/api/scalculate', calculateRoutes);




const PORT = process.env.PORT || 4000;
mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(()=> {
    console.log('Mongo connected');
    app.listen(PORT, ()=> console.log('Server listening on', PORT));
  })
  .catch(err => console.error(err));
