# Cognify Blockchain Deployment Guide

## Prerequisites

### 1. Install Node.js and npm
- Download from: https://nodejs.org/
- Verify: `node --version` and `npm --version`

### 2. Get a Polygon Wallet
- Install MetaMask: https://metamask.io/
- Create a new wallet or import existing
- **IMPORTANT**: Save your private key securely (never share it!)

### 3. Get Testnet MATIC
For Mumbai testnet deployment:
- Visit: https://faucet.polygon.technology/
- Select "Mumbai" network
- Enter your wallet address
- Receive free testnet MATIC (0.5 MATIC)

---

## Step 1: Setup Blockchain Project

```bash
cd blockchain
npm install
```

This installs Hardhat and all dependencies.

---

## Step 2: Configure Environment

Create `.env` file in `blockchain/` directory:

```bash
cp .env.example .env
```

Edit `.env` and add:

```bash
# Your wallet private key (WITHOUT 0x prefix)
DEPLOYER_PRIVATE_KEY=your_private_key_here

# Polygon Mumbai RPC (free)
POLYGON_MUMBAI_RPC=https://rpc-mumbai.maticvigil.com

# Optional: PolygonScan API key for verification
POLYGONSCAN_API_KEY=your_api_key_here
```

**Security Note**: Never commit `.env` to Git!

---

## Step 3: Compile Smart Contract

```bash
npm run compile
```

Expected output:
```
Compiled 1 Solidity file successfully
```

---

## Step 4: Deploy to Mumbai Testnet

```bash
npm run deploy:mumbai
```

Expected output:
```
🚀 Deploying CertificateRegistry contract...
📝 Deploying with account: 0x...
💰 Account balance: 0.5 MATIC
✅ CertificateRegistry deployed to: 0x...
📄 Contract address saved to: ../../backend/.env.contract
```

**Save the contract address!** You'll need it for backend configuration.

---

## Step 5: Verify Contract on PolygonScan

```bash
npx hardhat verify --network mumbai <CONTRACT_ADDRESS>
```

This makes your contract code publicly viewable on Mumbai PolygonScan.

---

## Step 6: Configure Backend

### 6.1 Encrypt Private Key

```bash
cd ../backend
go run scripts/encrypt_key.go
```

Follow prompts to encrypt your private key with a passphrase.

### 6.2 Update Backend .env

Add to `backend/.env`:

```bash
# Blockchain Mode
BLOCKCHAIN_MODE=real

# Blockchain Configuration
BLOCKCHAIN_RPC_URL=https://rpc-mumbai.maticvigil.com
CONTRACT_ADDRESS=<from_deployment_output>
PRIVATE_KEY_ENCRYPTED=<from_encrypt_key_output>
ENCRYPTION_PASSPHRASE=<your_secure_passphrase>
CHAIN_ID=80001
GAS_LIMIT=300000
MAX_GAS_PRICE=100000000000
```

---

## Step 7: Test Backend Integration

### 7.1 Start Backend

```bash
cd backend
go run ./cmd/cognify
```

Expected output:
```
✅ Configuration loaded
   Blockchain Mode: real
   Chain ID: 80001
   Contract: 0x...
🔗 Initializing REAL blockchain client...
   RPC: https://rpc-mumbai.maticvigil.com
   Contract: 0x...
   Wallet: 0x...
   Chain ID: 80001
✅ Real blockchain client initialized
🚀 Cognify Backend starting on port 8080
```

### 7.2 Test Certificate Generation

```bash
curl -X POST http://localhost:8080/api/instructor/certificate/generate \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "student123",
    "userName": "John Doe",
    "courseId": "blockchain-101",
    "courseName": "Blockchain Fundamentals",
    "marks": 95.5,
    "walletAddress": "0xYourWalletAddress"
  }'
```

Expected response:
```json
{
  "success": true,
  "certificateHash": "8f434346648f6b96...",
  "blockchainTx": "0x...",
  "trustScore": 70
}
```

### 7.3 Verify on Blockchain

Visit Mumbai PolygonScan:
```
https://mumbai.polygonscan.com/tx/<TRANSACTION_HASH>
```

You should see your transaction!

### 7.4 Test Verification

```bash
curl -X POST http://localhost:8080/api/verify-certificate \
  -H "Content-Type: application/json" \
  -d '{
    "certificateHash": "<hash_from_generation>"
  }'
```

Expected response:
```json
{
  "verified": true,
  "studentName": "John Doe",
  "courseName": "Blockchain Fundamentals",
  "blockchainTx": "0x...",
  "trustScore": 70
}
```

---

## Troubleshooting

### Error: "insufficient funds for gas"
- Get more testnet MATIC from faucet
- Check wallet balance: https://mumbai.polygonscan.com/address/YOUR_ADDRESS

### Error: "failed to connect to blockchain"
- Check RPC URL is correct
- Try alternative RPC: https://polygon-mumbai.g.alchemy.com/v2/demo

### Error: "invalid private key"
- Ensure private key has NO "0x" prefix
- Verify encryption passphrase is correct

### Error: "contract call failed"
- Ensure contract is deployed correctly
- Check contract address in .env
- Verify you're on the correct network (Mumbai = 80001)

---

## Production Deployment (Polygon Mainnet)

### 1. Get Real MATIC
- Buy MATIC from exchange (Coinbase, Binance, etc.)
- Transfer to your deployment wallet
- Need ~0.1 MATIC for deployment + operations

### 2. Update Configuration

```bash
# In blockchain/.env
POLYGON_RPC=https://polygon-rpc.com
DEPLOYER_PRIVATE_KEY=<mainnet_private_key>

# In backend/.env
BLOCKCHAIN_RPC_URL=https://polygon-rpc.com
CHAIN_ID=137
```

### 3. Deploy to Mainnet

```bash
npm run deploy:polygon
```

### 4. Verify on PolygonScan

```bash
npx hardhat verify --network polygon <CONTRACT_ADDRESS>
```

---

## Security Checklist

- [ ] Private keys stored encrypted
- [ ] `.env` files in `.gitignore`
- [ ] Separate wallets for testnet and mainnet
- [ ] Backup private keys securely
- [ ] Monitor gas costs
- [ ] Set up alerts for failed transactions
- [ ] Regular security audits

---

## Cost Estimation

### Mumbai Testnet (FREE)
- Deployment: Free
- Minting: Free
- Verification: Free

### Polygon Mainnet
- Deployment: ~$0.50-$2 USD (one-time)
- Minting: ~$0.001-$0.01 USD per certificate
- Verification: Free (read-only)
- Monthly cost for 1000 certificates: ~$1-$10 USD

---

## Support

- Polygon Documentation: https://docs.polygon.technology/
- Hardhat Documentation: https://hardhat.org/docs
- Mumbai Faucet: https://faucet.polygon.technology/
- PolygonScan: https://polygonscan.com/
