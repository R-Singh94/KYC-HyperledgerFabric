const shim = require('fabric-shim');
const Chaincode = class {
   async Init(stub){
       let ret = stub.getFunctionAndParameters();
       let args = ret.params;
       let a = args[0];
       let aValue = args[1];
       let b = args[2];
       let bValue = args[3];
await stub.putState(a, Buffer.from(aValue));
await stub.putState(b, Buffer.from(bValue));

return shim.success(Buffer.from("Initialized Successfully"));
   }
   async Invoke(stub){
       let ret = stub.getFunctionAndParameters();
       let fcn = [ret.fcn];

       return fcn(ret.params);
   }
   async transfer(stub, args){
       let a = args[0];
       let b = args[1];
       let value = args[2];
   let amount = parseInt(value);

   let aBalance = await stub.getState(a);
   let bBalance = await stub.getState(b);

   aBalance = parseInt(aBalance) - amount;
   bBalance = parseInt(bBalance) + amount;

   await stub.putState(a, Buffer.from(aBalance.toString()));
   await stub.putState(b, Buffer.from(bBalance.toString()));

   return shim.success(Buffer.from("Transfer Successful!!"));
   }
   async query(stub, args){
       let a = args[0]
       let aBalance = stub.getState(a);
   return shim.success(aBalance);
   }
};
shim.start(new Chaincode());
