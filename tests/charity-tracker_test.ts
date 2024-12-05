import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test charity registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const charity = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('charity-tracker', 'register-charity', [
                types.principal(charity.address),
                types.ascii("Test Charity"),
                types.ascii("A test charity organization")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test donation flow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const charity = accounts.get('wallet_1')!;
        const donor = accounts.get('wallet_2')!;
        
        // First register charity
        let block = chain.mineBlock([
            Tx.contractCall('charity-tracker', 'register-charity', [
                types.principal(charity.address),
                types.ascii("Test Charity"),
                types.ascii("A test charity organization")
            ], deployer.address)
        ]);
        
        // Then make donation
        let donationBlock = chain.mineBlock([
            Tx.contractCall('charity-tracker', 'make-donation', [
                types.principal(charity.address),
                types.uint(1000)
            ], donor.address)
        ]);
        
        donationBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check total donations
        let infoBlock = chain.mineBlock([
            Tx.contractCall('charity-tracker', 'get-total-donations', [
                types.principal(charity.address)
            ], deployer.address)
        ]);
        
        assertEquals(infoBlock.receipts[0].result.expectOk(), types.uint(1000));
    }
});
