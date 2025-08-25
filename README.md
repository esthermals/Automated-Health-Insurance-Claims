# 🏥 Insure - Automated Health Insurance Claims

A smart contract system built on Stacks that automatically processes and pays out health insurance claims upon verifiable diagnosis.

## 🚀 Features

- 📋 **Policy Creation**: Create health insurance policies with customizable coverage limits and duration
- 🩺 **Doctor Authorization**: Authorize medical professionals to submit diagnoses
- 📝 **Diagnosis Submission**: Verified doctors can submit patient diagnoses with validity periods  
- 💰 **Claim Processing**: Automatic claim validation and payout based on verified diagnoses
- 🔧 **Policy Management**: Suspend, reactivate, and extend insurance policies
- 📊 **Analytics**: Track contract statistics and policy status

## 💼 Contract Functions

### Admin Functions
- `authorize-doctor` - Add verified doctors to the system
- `revoke-doctor` - Remove doctor authorization
- `suspend-policy` - Temporarily suspend a policy
- `reactivate-policy` - Reactivate a suspended policy

### User Functions
- `create-policy` - Purchase an insurance policy
- `extend-policy` - Extend policy duration
- `submit-claim` - File a claim for medical expenses

### Doctor Functions  
- `submit-diagnosis` - Submit verified patient diagnosis

### System Functions
- `process-claim` - Automatically process and pay valid claims

## 🔍 Read-Only Functions

- `get-policy` - Retrieve policy details
- `get-claim` - Get claim information
- `get-diagnosis` - View diagnosis data
- `is-doctor-authorized` - Check doctor verification status
- `get-doctor-info` - Get doctor details and specialization
- `get-policy-status` - Check if policy is active/expired
- `get-contract-stats` - View overall contract statistics

## 🛠 Usage Instructions

### Creating a Policy
```clarity
(contract-call? .Insure create-policy u100000 u1000)
```
Creates a policy with 100,000 STX coverage limit for 1,000 blocks duration.

### Authorizing a Doctor (Admin Only)
```clarity
(contract-call? .Insure authorize-doctor 'SP1ABC... "Cardiology")
```

### Submitting a Diagnosis (Authorized Doctor)
```clarity
(contract-call? .Insure submit-diagnosis 'SP1PATIENT... "HEART001" u500)
```

### Filing a Claim
```clarity
(contract-call? .Insure submit-claim u1 "HEART001" u5000)
```

### Processing Claims
```clarity
(contract-call? .Insure process-claim u1)
```

## 💡 How It Works

1. 👤 **Users** purchase insurance policies by paying premiums
2. 🩺 **Authorized doctors** submit verified diagnoses for patients
3. 📋 **Policyholders** file claims referencing their diagnosis codes
4. ⚡ **Smart contract** automatically validates diagnoses and processes payments
5. 💸 **Claims** are paid out instantly if valid diagnosis exists

## 🔐 Security Features

- Only contract owner can authorize/revoke doctors
- Claims require valid, unexpired diagnoses from authorized doctors
- Policy holders can only file claims for their own policies
- Built-in checks for policy expiration and coverage limits
- Premium pool management prevents overspending

## 📈 Contract Statistics

Track key metrics including:
- Total policies created
- Total claims processed  
- Premium pool size
- Total claims paid out
- Active diagnoses count

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🚢 Deployment

Deploy to testnet:
```bash
clarinet deploy --testnet
```

Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

---

**⚠️ Disclaimer**: This is experimental software. Use at your own risk. Not financial or medical advice.
