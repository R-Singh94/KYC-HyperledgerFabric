
'use strict';
const shim = require('fabric-shim');
const util = require('util');
const { Contract, Context } = require('fabric-contract-api');


let chaincode = class {
        async Init(Stub){
                console.info("Instantiated chaincode");
                return shim.success();
        }

        async Invoke(Stub){
                let ret = Stub.getFunctionAndParameters();
                console.info(ret);

                let method = this[ret.fcn];
                if(!method){
                        console.error("no function of name:' + ret.fcn + ' found'");
                        throw new error('Received unknown function ' + ret.fcn + ' invocation');
                }
                
                try{
                        let payload = await method(Stub, ret.params);
                        return shim.success(payload);
                } catch(err){
                        console.log(err);
                        return shim.error(err);
                }
        }
        

        // methods
        async test(Stub){
                return "test success"
        }

        async initLedger(Stub,args){
                console.info("ledger initialize");
                let docs = [];
                docs.push({
                        id:1,
                        name:"test",
                        hash:"later",
                        type:1
                });

                docs.push({
                        id:2,
                        name:"test-2",
                        hash:"later-2",
                        type:1
                });

                docs.forEach((doc,index)=>{
                        await Stub.putState('doc'+index,Buffer.from(JSON.stringify(doc)));
                        console.info("added" + doc);
                })
                console.info("Initialization complete");
        }

        async changeDocument(Stub, args){
                console.info("modification started");
                if(args.length !=2){
                        throw new error("2 arguements expected");
                }

                let docBytes= await Stub.getState(args[0]);
                let doc = JSON.parse(docBytes);
                doc.hash=arg[2];

                await Stub.putState(args[0],Buffer.from(JSON.stringify(doc)));
                console.info("modification done");

        }
}

shim.start(new chaincode());