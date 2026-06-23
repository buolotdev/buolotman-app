# BOULOT MAN PLATFORM

## TECHNICAL SPECIFICATION & BUILD DOCUMENT

---

## 1. PROJECT OVERVIEW

**Boulot Man** is a multi-sided digital marketplace platform designed to connect **clients**, **technicians**, **freelancers**, and **companies** across Africa. The platform supports task posting, service listings, bidding, secure payments, verification, and long-term project engagement.

The system must be scalable, modular, and API-driven to support web, mobile, and third-party integrations.

---

## 2. CORE USER ROLES

### 2.1 Clients

* Individuals
* Businesses
* Enterprises

### 2.2 Technicians / Freelancers

* Skilled technicians
* Engineers
* Handymen / service workers

### 2.3 Companies

* Registered service companies
* Contractors
* Enterprises

### 2.4 Platform Administrators

* Super Admin
* Operations Admin
* Verification & Compliance Officers
* Finance & Dispute Officers

---

## 3. PLATFORM ARCHITECTURE

### 3.1 Frontend

* Web App (Responsive, Desktop-first)
* Future Mobile Apps (iOS / Android)

**Recommended Stack**

* HTML5, CSS3, JavaScript
* React.js or Next.js
* TailwindCSS or custom design system

### 3.2 Backend

* API-first architecture

**Recommended Stack**

* Python (Django + Django REST Framework)
* Node.js (optional microservices)

### 3.3 Database

**Primary**

* PostgreSQL

**Secondary / Caching**

* Redis

### 3.4 Infrastructure

* Cloud hosting (AWS / GCP / Azure)
* Dockerized services
* Nginx
* CI/CD pipelines

---

## 4. AUTHENTICATION & SECURITY

### 4.1 Authentication

* Email & password
* Phone OTP verification
* Social login (optional)

### 4.2 Authorization

* Role-based access control (RBAC)

### 4.3 Security

* Encrypted passwords (bcrypt)
* HTTPS only
* JWT access & refresh tokens
* Rate limiting

---

## 5. CORE FEATURES

## 5.1 HOME PAGE

* Global search (task / service / category / location)
* Live task activity ticker
* Featured technicians
* Featured companies
* Category sidebar
* Trust & verification indicators

---

## 5.2 CLIENT FEATURES

### 5.2.1 Client Dashboard

* Profile management
* Task history
* Active tasks
* Saved professionals
* Messages
* Payments

### 5.2.2 Post a Task

Fields:

* Task title
* Category & subcategory
* Description
* Onsite / Remote / Hybrid
* Location (IP-based city & country)
* Schedule (date, urgency: urgent / flexible / programmed)
* Budget (fixed / range)
* Preferred payment method

Flow:

1. Draft
2. Preview
3. Publish

---

### 5.2.3 Task Management

* Receive bids
* Compare offers
* View technician profiles
* Accept / reject offers
* Track task status

---

## 5.3 TECHNICIAN / FREELANCER FEATURES

### 5.3.1 Technician Profile

* Personal details
* Skills & categories
* Experience
* Certifications
* Portfolio / gallery
* Availability
* Pricing

### 5.3.2 Post a Service

* Service title
* Category
* Description
* Service type (onsite / remote)
* Coverage area
* Pricing model

### 5.3.3 Browse & Bid on Tasks

* Task feed
* Filters (category, budget, location)
* Submit bid
* Messaging

### 5.3.4 Earnings & Wallet

* Pending earnings
* Available balance
* Withdrawals
* Transaction history

---

## 5.4 COMPANY FEATURES

### 5.4.1 Company Registration

* Legal details
* Registration documents
* Verification

### 5.4.2 Company Profile

* Company overview
* Services
* Team
* Portfolio
* Ratings

### 5.4.3 Post Company Services

* Service catalog
* Pricing models
* Availability

### 5.4.4 Projects & Contracts

* Long-term contracts
* Milestone tracking
* Escrow payments

---

## 5.5 PAYMENTS & ESCROW

### 5.5.1 Payment Flow

* Client deposits funds
* Funds held in escrow
* Release upon completion

### 5.5.2 Payment Methods

* Mobile money
* Bank transfer
* Card payments

---

## 5.6 MESSAGING SYSTEM

* Client ↔️ Technician chat
* Client ↔️ Company chat
* File sharing
* System notifications

---

## 5.7 VERIFICATION & TRUST

### Technician Verification

* ID verification
* Skill screening
* Certification upload

### Company Verification

* Business registration
* Compliance review

---

## 5.8 DISPUTE RESOLUTION

* Dispute initiation
* Evidence submission
* Admin mediation
* Final resolution

---

## 5.9 HELP CENTER & RESOURCES

* FAQs
* Guides
* Policies
* Safety rules

---

## 6. ADMIN PANEL

### 6.1 User Management

* Approve / suspend users

### 6.2 Task Oversight

* Monitor live tasks

### 6.3 Financial Management

* Escrow monitoring
* Payout approvals

### 6.4 Content Management

* Categories
* Pages

---

## 7. API MODULES (HIGH LEVEL)

* Auth API
* User API
* Task API
* Service API
* Bidding API
* Messaging API
* Payment API
* Verification API
* Dispute API

---

## 8. NON-FUNCTIONAL REQUIREMENTS

* High availability
* Performance optimized
* Scalable architecture
* Audit logs
* Compliance readiness

---

## 9. FUTURE EXTENSIONS

* Mobile apps
* AI task matching
* Subscription tiers
* Analytics dashboard
* Enterprise integrations

---

## 10. DELIVERY EXPECTATION

Developers must:

* Follow modular architecture
* Write clean, documented code
* Ensure security best practices
* Deliver test coverage

---

**END OF DOCUMENT**