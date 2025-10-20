# 💰 Deductible & Co-Payment System Feature

## Overview

This feature introduces realistic insurance economics to the Insure smart contract by implementing **deductible tiers** and **co-payment percentages** for health insurance policies. It enables insurance platforms to implement industry-standard cost-sharing mechanisms while tracking patient financial responsibility.

---

## ✨ Key Capabilities

### 💵 Patient Cost Calculation
- **Deductible Tracking**: Per-policy deductible amounts with year-to-date accumulation
- **Co-Payment Percentages**: Configurable cost-sharing from 0-100%
- **Insurance Payout**: Automatic calculation of insurance company liability after patient costs

### 📊 Transparency & Control
- **Real-Time Claim Breakdown**: Preview cost distribution before processing
- **Annual Reset**: Deductible accumulators can be reset for policy year renewals
- **Total Deductibles Collected**: System-wide tracking of all deductible amounts

### 🔧 Configuration Flexibility
- **Custom Deductibles**: Set different deductible amounts per policy
- **Adjustable Co-Pays**: Support for any co-payment percentage (0-100%)
- **Policy-Level Management**: Independent configuration for each policy

---

## 🏗️ Technical Implementation

### New Data Structures

#### Extended Policies Map
Three new fields added to the `policies` map:
```clarity
deductible: uint                    ;; Annual deductible in micro-STX
copay-percentage: uint              ;; Co-payment percentage (0-100)
deductible-accumulator: uint        ;; Year-to-date deductible paid
```

#### New Data Variable
```clarity
(define-data-var total-deductibles-collected uint u0)
```

### New Error Constants
```clarity
(define-constant err-invalid-deductible (err u118))
(define-constant err-invalid-copay (err u119))
```

---

## 📋 Public Functions

### 1. configure-deductible
**Owner-only function** to set deductible and co-payment terms for a policy.

```clarity
(define-public (configure-deductible (policy-id uint) (deductible-amount uint) (copay-pct uint))
```

**Parameters:**
- `policy-id`: uint - The policy to configure
- `deductible-amount`: uint - Annual deductible in micro-STX
- `copay-pct`: uint - Co-payment percentage (must be ≤ 100)

**Returns:** `(ok true)` or error

**Security:**
- Owner-only
- Validates copay percentage ≤ 100
- Checks policy exists

---

### 2. reset-deductible-accumulator
**Owner-only function** to reset a policy's year-to-date deductible accumulator (used for policy renewals).

```clarity
(define-public (reset-deductible-accumulator (policy-id uint))
```

**Parameters:**
- `policy-id`: uint - The policy to reset

**Returns:** `(ok true)` or error

**Security:**
- Owner-only
- Checks policy exists

---

### 3. Enhanced process-claim
Modified to calculate and apply deductibles and co-payments during claim processing.

**New Calculation Logic:**
1. Calculate remaining annual deductible
2. Apply deductible to claim amount
3. Calculate co-payment on remaining balance
4. Calculate insurance payout
5. Update deductible accumulator
6. Return cost breakdown

**Return Value:**
```clarity
{
  total-claim: uint,           ;; Original claim amount
  deductible-charge: uint,     ;; Amount applied to deductible
  copay-charge: uint,          ;; Co-payment amount
  insurance-pays: uint         ;; Final insurance payout
}
```

---

## 🔍 Read-Only Functions

### 1. calculate-claim-breakdown
**Query-only function** to preview claim cost distribution before processing.

```clarity
(define-read-only (calculate-claim-breakdown (policy-id uint) (claim-amount uint))
```

**Returns:**
```clarity
{
  total-claim: uint,
  deductible-charge: uint,
  copay-charge: uint,
  insurance-pays: uint,
  remaining-annual-deductible: uint
}
```

---

### 2. get-policy-deductible-info
**Query-only function** to retrieve deductible configuration and accumulation for a policy.

```clarity
(define-read-only (get-policy-deductible-info (policy-id uint))
```

**Returns:**
```clarity
{
  deductible: uint,
  copay-percentage: uint,
  deductible-accumulator: uint,
  remaining-deductible: uint
}
```

---

### 3. get-total-deductibles-collected
**Query-only function** to retrieve system-wide total deductibles collected.

```clarity
(define-read-only (get-total-deductibles-collected)
```

**Returns:** `(ok uint)` - Total deductibles collected across all policies

---

## 💡 Usage Examples

### Example 1: Configure a Policy with Deductible
```clarity
;; Set $1,000 deductible and 20% co-pay for policy 1
(contract-call? .Insure configure-deductible u1 u1000000000 u20)
;; Returns: (ok true)
```

### Example 2: Preview Claim Cost Breakdown
```clarity
;; See how a $5,000 claim would be split
(contract-call? .Insure calculate-claim-breakdown u1 u5000000000)
;; Returns:
;; {
;;   total-claim: u5000000000,
;;   deductible-charge: u1000000000,
;;   copay-charge: u800000000,     ;; 20% of $4,000
;;   insurance-pays: u3200000000,
;;   remaining-annual-deductible: u0
;; }
```

### Example 3: Check Policy Deductible Status
```clarity
;; Get deductible info for policy 1
(contract-call? .Insure get-policy-deductible-info u1)
;; Returns:
;; {
;;   deductible: u1000000000,
;;   copay-percentage: u20,
;;   deductible-accumulator: u1000000000,  ;; Already paid
;;   remaining-deductible: u0              ;; All deductible met
;; }
```

### Example 4: Reset Deductible for Annual Renewal
```clarity
;; Reset policy 1's deductible accumulator for new year
(contract-call? .Insure reset-deductible-accumulator u1)
;; Returns: (ok true)
```

---

## 🔐 Security Considerations

### Access Control
- ✅ Configuration functions are **owner-only**
- ✅ All state changes checked with assertions
- ✅ Policy existence validated before modifications

### Input Validation
- ✅ Co-payment percentage capped at 100%
- ✅ All arithmetic uses unsigned integers (no negative values)
- ✅ Deductible accumulator can't exceed deductible amount

### Financial Safety
- ✅ Insurance only pays after deductible and co-pay applied
- ✅ Fund checks before transferring STX
- ✅ Immutable claim processing prevents double-payment

---

## 📊 Business Logic

### Claim Payment Flow
```
Claim Amount = $5,000
Deductible = $1,000
Co-Pay % = 20%

Step 1: Apply Deductible
  Amount After Deductible = $5,000 - $1,000 = $4,000

Step 2: Calculate Co-Payment
  Co-Pay Amount = $4,000 × 20% = $800

Step 3: Calculate Insurance Payout
  Insurance Pays = $4,000 - $800 = $3,200

Patient Pays: $1,000 (deductible) + $800 (copay) = $1,800
Insurance Pays: $3,200
```

### Deductible Accumulation
- Tracks cumulative deductible paid per policy year
- Once deductible is met, future claims only apply co-payment
- Owner can reset accumulator at policy renewal

---

## 🧪 Testing Considerations

### Key Test Scenarios
1. ✅ Configure deductible with valid copay (0-100%)
2. ✅ Configure deductible with invalid copay (>100%) → Should fail
3. ✅ Calculate claim breakdown on fresh policy (full deductible applies)
4. ✅ Calculate claim breakdown after deductible met (only copay applies)
5. ✅ Process claim updates deductible accumulator
6. ✅ Reset deductible accumulator to zero
7. ✅ Query policy deductible info
8. ✅ Track total deductibles collected system-wide

---

## 📦 Code Statistics

- **New Functions**: 2 public + 3 read-only = 5 functions
- **New Error Constants**: 2
- **New Data Variable**: 1
- **Lines Added**: ~150 (including new functions)
- **Contract Size**: 540 lines total
- **Status**: ✅ Passes `clarinet check` with no errors

---

## 🚀 Deployment Notes

### Backward Compatibility
- ✅ New policies created with deductible defaults to 0 (no deductible)
- ✅ Existing policies continue to work (new fields initialized)
- ✅ No breaking changes to existing functions

### Migration Path
1. Deploy contract to testnet
2. Test deductible/copay configurations with sample policies
3. Configure policies with appropriate terms
4. Reset deductibles at policy year boundaries
5. Monitor deductible collection metrics

---

## 🎯 Future Enhancements

Potential extensions for future iterations:
- Multi-tier deductibles (individual vs. family)
- Out-of-pocket maximum caps
- Deductible waiver for preventive care
- Deductible carryover between years
- Differential co-pays by service type

---

## 📞 Support

For questions or issues with this feature:
1. Review the examples above
2. Check the inline function documentation
3. Verify error constants match your implementation
4. Test with `clarinet test` suite

---

**Status**: ✅ Ready for implementation  
**Branch**: `feat/deductible-copay-system`  
**Version**: 1.0.0
