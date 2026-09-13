// Dependency-free reproducible RV32I program builder: node scripts/generate_programs.js
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..', 'programs');
let code=[], listing=[];
function emit(word,text) { listing.push(`${(code.length*4).toString(16).padStart(8,'0')}  ${(word>>>0).toString(16).padStart(8,'0')}  ${text}`);code.push(word>>>0); }
function r(f3,f7,rd,a,b,name) { emit((f7<<25)|(b<<20)|(a<<15)|(f3<<12)|(rd<<7)|0x33,`${name} x${rd},x${a},x${b}`); }
function i(f3,rd,a,imm,name='addi',opcode=0x13) { emit(((imm&4095)<<20)|(a<<15)|(f3<<12)|(rd<<7)|opcode,`${name} x${rd},x${a},${imm}`); }
function u(rd,imm,opcode,name) { emit((imm<<12)|(rd<<7)|opcode,`${name} x${rd},0x${(imm>>>0).toString(16)}`); }
function b(f3,a,z,imm,name) { emit(((imm>>12&1)<<31)|((imm>>5&63)<<25)|(z<<20)|(a<<15)|(f3<<12)|((imm>>1&15)<<8)|((imm>>11&1)<<7)|0x63,`${name} x${a},x${z},${imm}`); }
function j(rd,imm) { emit(((imm>>20&1)<<31)|((imm>>1&1023)<<21)|((imm>>11&1)<<20)|((imm>>12&255)<<12)|(rd<<7)|0x6f,`jal x${rd},${imm}`); }
function sw(a,z,imm) { emit(((imm>>5&127)<<25)|(z<<20)|(a<<15)|(2<<12)|((imm&31)<<7)|0x23,`sw x${z},${imm}(x${a})`); }
function save(name) { fs.writeFileSync(path.join(root,name+'.hex'),code.map(x=>x.toString(16).padStart(8,'0')).join('\n')+'\n');fs.writeFileSync(path.join(root,name+'.lst'),listing.join('\n')+'\n');code=[];listing=[]; }
const ops=[[0,0,'add'],[0,32,'sub'],[7,0,'and'],[6,0,'or'],[4,0,'xor'],[2,0,'slt'],[3,0,'sltu'],[1,0,'sll'],[5,0,'srl'],[5,32,'sra']];
function arithmetic() {
  i(0,1,0,-1);i(0,2,0,1);i(0,3,0,31);u(4,0x80000,0x37,'lui');i(0,5,0,33);
  ops.forEach(([f,g,n],k)=>r(f,g,6+k,1,k>=7?5:2,n));
  [[0,-2048,'addi'],[7,255,'andi'],[6,256,'ori'],[4,-1,'xori'],[2,0,'slti'],[3,-1,'sltiu'],[1,31,'slli'],[5,31,'srli'],[5,1055,'srai']].forEach(([f,v,n],k)=>i(f,6+k,4,v,n));
  r(0,0,0,1,2,'add');i(0,0,0,123);i(0,2,2,-2);u(16,0x12345,0x17,'auipc');u(17,0xfffff,0x17,'auipc');
  // Fixed PRNG: mixed registers exercise dependencies without pipeline machinery.
  let seed=0x12345678;
  const rand=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed;};
  for(let n=0;n<160;n++) { let [f,g,name]=ops[rand()%ops.length];r(f,g,6+rand()%18,rand()%24,rand()%24,name); }
}
function branches() {
  i(0,1,0,-1);i(0,2,0,1);
  for(const [f,n,t1,t2,nt1,nt2] of [[0,'beq',1,1,1,2],[1,'bne',1,2,1,1],[4,'blt',1,2,2,1],[5,'bge',2,1,1,2],[6,'bltu',2,1,1,2],[7,'bgeu',1,2,2,1]]) {
    b(f,t1,t2,8,n);i(0,30,30,1);b(f,nt1,nt2,8,n);i(0,30,30,2);
  }
  i(0,20,0,3);i(0,20,20,-1);b(1,20,0,-4,'bne');
  j(21,8);i(0,30,30,8);
  const target=(code.length+3)*4;
  i(0,22,0,target+5);i(0,23,22,-4,'jalr',0x67);i(0,30,30,16);
}
function memory() {
  u(25,0x10000,0x37,'lui');i(0,1,0,-1);sw(25,1,0);i(2,2,25,0,'lw',3);
  i(0,26,25,2047);i(0,26,26,1);sw(26,1,0);i(2,3,26,0,'lw',3);
  i(0,27,26,2044);sw(27,2,0);i(2,4,27,0,'lw',3);
  i(0,5,0,123);sw(27,5,-4);i(2,6,27,-4,'lw',3);i(2,0,25,0,'lw',3);
}
arithmetic();j(0,0);save('arithmetic');
branches();j(0,0);save('branch');
memory();j(0,0);save('load_store');
arithmetic();branches();memory();j(0,0);save('isa');
console.log('Generated arithmetic, branch, load_store and isa programs with disassembly listings.');
