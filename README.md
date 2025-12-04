# 📘 **An Intelligent Career Planning Tool for IT Undergraduates in Sri Lanka**

Our application connects IT undergraduates in Sri Lanka with their desired company job roles by mapping their academic and skill progress with real industry expectations. It also helps companies discover and hire qualified talent faster by analyzing student profiles, projects, and skillsets.

---

## 🚀 **Project Overview**

This system bridges the gap between **students** and **IT companies** by:

* Guiding undergraduates toward suitable career paths.
* Creating Competition Platform to where students can compete with other university students for specific company job roles positions during university time.
* Recommending job roles based on skills, projects, and industry standards.
* Allowing companies to search, filter, and hire top talent.
* Providing AI-powered job recommendations through a Python-based ML model.

---

## 🎥 **Project Videos**

* 🔹 **Introduction Video:** [Introduction video](https://youtu.be/eYx42vftYJw?si=f-VKJGIXj76lVWVy)
* 🔹 **Demo / Walkthrough Video:** [Demo Video](https://youtu.be/khaW5lh2Bhg?si=YCQtDWDPe0x3Vva-)

---

## 📁 **Folder Structure**

```
Carrer_tool/                   # Main project folder
│
├── Career_tool/               # Frontend (Flutter)
│   └── ...                  
│
└── Backend/                   # Backend (Node.js + Python Model)
    ├── job_recommender/       # Python ML environment
    │   └── venv/
    └── ...
```

---

## 🛠️ **Technologies Used**

### **Frontend**

* Flutter (Dart)
* Android Studio (emulator/debugging)

### **Backend**

* Node.js (API server)
* MongoDB (Database)
* Python (Machine Learning Model)

### **Development Tools**

* VS Code
* Git & GitHub

---

## 💻 **How to Run the Project Locally**

### **1️⃣ Clone the Repository**

```bash
git clone <your-repo-link>
cd Carrer_tool
```

---

## **2️⃣ Start the Backend (Node.js)**

```bash
cd Backend
npm install
npm run dev
```

---

## **3️⃣ Run the Python Virtual Environment (ML Model)**

Open a **new terminal**:

```bash
cd Backend/job_recommender
venv\Scripts\activate
```

---

## **4️⃣ Start the Flutter Application**

In another terminal:

```bash
cd Career_tool
flutter pub get
flutter run
```

The entire application (Flutter UI + Node.js API + Python ML model) should now be running.

---

## 📐 **System Architecture**

**Frontend (Flutter)**
⬇ connects to
**Backend API (Node.js + Express)**
⬇ communicates with
**Machine Learning Model (Python)**
⬇ reads/writes
**Database (MongoDB)**

---

## 🔥 **Key Features**

### 🎓 For Undergraduates

* Personalized IT career paths.
* Compete with real competitors who are seeking dream of working in same company same job role.
* Job recommendation using ML.
* Profile building (skills, projects, achievements).
* Real-time company job listings.

### 🏢 For Companies

* Create company Job posts.
* View rank under specific compnay job roles.
* Give the marks for certifications and badges that students have gained,
* Give the marks for projects that students have ganined.

---

## 🤝 **Contributions**

Pull requests, suggestions, and improvements are welcome.

---

## 📬 **Contact**

If you have questions or issues, feel free to open an Issue on GitHub.
email: sheshanhebron61@gmail.com
