
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0ac78793          	addi	a5,a5,172 # 80006110 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd843f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	4fe080e7          	jalr	1278(ra) # 8000262a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	876080e7          	jalr	-1930(ra) # 80001a36 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2ac080e7          	jalr	684(ra) # 80002474 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fea080e7          	jalr	-22(ra) # 800021c0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3c2080e7          	jalr	962(ra) # 800025d4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	38e080e7          	jalr	910(ra) # 80002680 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dde080e7          	jalr	-546(ra) # 80002224 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00025797          	auipc	a5,0x25
    8000047c:	db078793          	addi	a5,a5,-592 # 80025228 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07a323          	sw	zero,1446(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72923          	sw	a5,818(a4) # 800088b0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	536dad83          	lw	s11,1334(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4e050513          	addi	a0,a0,1248 # 80010ad8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	38250513          	addi	a0,a0,898 # 80010ad8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	36648493          	addi	s1,s1,870 # 80010ad8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	32650513          	addi	a0,a0,806 # 80010af8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0b27a783          	lw	a5,178(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0827b783          	ld	a5,130(a5) # 800088b8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	08273703          	ld	a4,130(a4) # 800088c0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	298a0a13          	addi	s4,s4,664 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	05048493          	addi	s1,s1,80 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	05098993          	addi	s3,s3,80 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	992080e7          	jalr	-1646(ra) # 80002224 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	22a50513          	addi	a0,a0,554 # 80010af8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fd27a783          	lw	a5,-46(a5) # 800088b0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fd873703          	ld	a4,-40(a4) # 800088c0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fc87b783          	ld	a5,-56(a5) # 800088b8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1fc98993          	addi	s3,s3,508 # 80010af8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fb448493          	addi	s1,s1,-76 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fb490913          	addi	s2,s2,-76 # 800088c0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	8a4080e7          	jalr	-1884(ra) # 800021c0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1c648493          	addi	s1,s1,454 # 80010af8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7bd23          	sd	a4,-134(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	13c48493          	addi	s1,s1,316 # 80010af8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00026797          	auipc	a5,0x26
    80000a02:	9c278793          	addi	a5,a5,-1598 # 800263c0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	11290913          	addi	s2,s2,274 # 80010b30 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	07650513          	addi	a0,a0,118 # 80010b30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00026517          	auipc	a0,0x26
    80000ad2:	8f250513          	addi	a0,a0,-1806 # 800263c0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	04048493          	addi	s1,s1,64 # 80010b30 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	02850513          	addi	a0,a0,40 # 80010b30 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	ffc50513          	addi	a0,a0,-4 # 80010b30 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	eaa080e7          	jalr	-342(ra) # 80001a1a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e78080e7          	jalr	-392(ra) # 80001a1a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e6c080e7          	jalr	-404(ra) # 80001a1a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e54080e7          	jalr	-428(ra) # 80001a1a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	e14080e7          	jalr	-492(ra) # 80001a1a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	de8080e7          	jalr	-536(ra) # 80001a1a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b8a080e7          	jalr	-1142(ra) # 80001a0a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a4070713          	addi	a4,a4,-1472 # 800088c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b6e080e7          	jalr	-1170(ra) # 80001a0a <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	aea080e7          	jalr	-1302(ra) # 800029a8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	28a080e7          	jalr	650(ra) # 80006150 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	140080e7          	jalr	320(ra) # 8000200e <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	a28080e7          	jalr	-1496(ra) # 80001956 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a4a080e7          	jalr	-1462(ra) # 80002980 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a6a080e7          	jalr	-1430(ra) # 800029a8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	1f4080e7          	jalr	500(ra) # 8000613a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	202080e7          	jalr	514(ra) # 80006150 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	3a2080e7          	jalr	930(ra) # 800032f8 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	a46080e7          	jalr	-1466(ra) # 800039a4 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	9e4080e7          	jalr	-1564(ra) # 8000494a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	2ea080e7          	jalr	746(ra) # 80006258 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e7a080e7          	jalr	-390(ra) # 80001df0 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72223          	sw	a5,-1724(a4) # 800088c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9387b783          	ld	a5,-1736(a5) # 800088d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	692080e7          	jalr	1682(ra) # 800018c0 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	66a7be23          	sd	a0,1660(a5) # 800088d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <Create_Queue>:
#include "proc.h"
#include "defs.h"

#define rr
queue Create_Queue()
{
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
  queue qu;
  qu.front = 0;
  qu.rear = 0;
  qu.numitems = 0;
  return qu;
    8000183c:	00052223          	sw	zero,4(a0)
    80001840:	00052423          	sw	zero,8(a0)
    80001844:	00052623          	sw	zero,12(a0)
}
    80001848:	6422                	ld	s0,8(sp)
    8000184a:	0141                	addi	sp,sp,16
    8000184c:	8082                	ret

000000008000184e <enqueue>:

void enqueue(queue *qu, queue_element el)
{
    8000184e:	1141                	addi	sp,sp,-16
    80001850:	e422                	sd	s0,8(sp)
    80001852:	0800                	addi	s0,sp,16
  qu->arr[qu->rear] = el;
    80001854:	451c                	lw	a5,8(a0)
    80001856:	00278713          	addi	a4,a5,2
    8000185a:	070e                	slli	a4,a4,0x3
    8000185c:	972a                	add	a4,a4,a0
    8000185e:	e30c                	sd	a1,0(a4)
  qu->rear = (qu->rear + 1) % 64;
    80001860:	2785                	addiw	a5,a5,1
    80001862:	41f7d71b          	sraiw	a4,a5,0x1f
    80001866:	01a7571b          	srliw	a4,a4,0x1a
    8000186a:	9fb9                	addw	a5,a5,a4
    8000186c:	03f7f793          	andi	a5,a5,63
    80001870:	9f99                	subw	a5,a5,a4
    80001872:	c51c                	sw	a5,8(a0)
  qu->numitems++;
    80001874:	455c                	lw	a5,12(a0)
    80001876:	2785                	addiw	a5,a5,1
    80001878:	c55c                	sw	a5,12(a0)
  // if (el->pid > 9)
  // printf("%d %d %d\n", ticks, el->pid, el->mlfq_priority);
  return;
}
    8000187a:	6422                	ld	s0,8(sp)
    8000187c:	0141                	addi	sp,sp,16
    8000187e:	8082                	ret

0000000080001880 <dequeue>:

void dequeue(queue *qu)
{
    80001880:	1141                	addi	sp,sp,-16
    80001882:	e422                	sd	s0,8(sp)
    80001884:	0800                	addi	s0,sp,16
  if (!qu->numitems)
    80001886:	455c                	lw	a5,12(a0)
    80001888:	cf91                	beqz	a5,800018a4 <dequeue+0x24>
    return;
  qu->numitems--;
    8000188a:	37fd                	addiw	a5,a5,-1
    8000188c:	c55c                	sw	a5,12(a0)
  qu->front = (qu->front + 1) % 64;
    8000188e:	415c                	lw	a5,4(a0)
    80001890:	2785                	addiw	a5,a5,1
    80001892:	41f7d71b          	sraiw	a4,a5,0x1f
    80001896:	01a7571b          	srliw	a4,a4,0x1a
    8000189a:	9fb9                	addw	a5,a5,a4
    8000189c:	03f7f793          	andi	a5,a5,63
    800018a0:	9f99                	subw	a5,a5,a4
    800018a2:	c15c                	sw	a5,4(a0)
}
    800018a4:	6422                	ld	s0,8(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <front>:
queue_element front(queue qu)
{
    800018aa:	1141                	addi	sp,sp,-16
    800018ac:	e422                	sd	s0,8(sp)
    800018ae:	0800                	addi	s0,sp,16
  return qu.arr[qu.front];
    800018b0:	415c                	lw	a5,4(a0)
    800018b2:	0789                	addi	a5,a5,2
    800018b4:	078e                	slli	a5,a5,0x3
    800018b6:	953e                	add	a0,a0,a5
}
    800018b8:	6108                	ld	a0,0(a0)
    800018ba:	6422                	ld	s0,8(sp)
    800018bc:	0141                	addi	sp,sp,16
    800018be:	8082                	ret

00000000800018c0 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018c0:	7139                	addi	sp,sp,-64
    800018c2:	fc06                	sd	ra,56(sp)
    800018c4:	f822                	sd	s0,48(sp)
    800018c6:	f426                	sd	s1,40(sp)
    800018c8:	f04a                	sd	s2,32(sp)
    800018ca:	ec4e                	sd	s3,24(sp)
    800018cc:	e852                	sd	s4,16(sp)
    800018ce:	e456                	sd	s5,8(sp)
    800018d0:	e05a                	sd	s6,0(sp)
    800018d2:	0080                	addi	s0,sp,64
    800018d4:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018d6:	00010497          	auipc	s1,0x10
    800018da:	f0a48493          	addi	s1,s1,-246 # 800117e0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018de:	8b26                	mv	s6,s1
    800018e0:	00006a97          	auipc	s5,0x6
    800018e4:	720a8a93          	addi	s5,s5,1824 # 80008000 <etext>
    800018e8:	04000937          	lui	s2,0x4000
    800018ec:	197d                	addi	s2,s2,-1
    800018ee:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018f0:	00019a17          	auipc	s4,0x19
    800018f4:	6f0a0a13          	addi	s4,s4,1776 # 8001afe0 <tickslock>
    char *pa = kalloc();
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	1ee080e7          	jalr	494(ra) # 80000ae6 <kalloc>
    80001900:	862a                	mv	a2,a0
    if (pa == 0)
    80001902:	c131                	beqz	a0,80001946 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001904:	416485b3          	sub	a1,s1,s6
    80001908:	8595                	srai	a1,a1,0x5
    8000190a:	000ab783          	ld	a5,0(s5)
    8000190e:	02f585b3          	mul	a1,a1,a5
    80001912:	2585                	addiw	a1,a1,1
    80001914:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001918:	4719                	li	a4,6
    8000191a:	6685                	lui	a3,0x1
    8000191c:	40b905b3          	sub	a1,s2,a1
    80001920:	854e                	mv	a0,s3
    80001922:	00000097          	auipc	ra,0x0
    80001926:	81c080e7          	jalr	-2020(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	26048493          	addi	s1,s1,608
    8000192e:	fd4495e3          	bne	s1,s4,800018f8 <proc_mapstacks+0x38>
  }
}
    80001932:	70e2                	ld	ra,56(sp)
    80001934:	7442                	ld	s0,48(sp)
    80001936:	74a2                	ld	s1,40(sp)
    80001938:	7902                	ld	s2,32(sp)
    8000193a:	69e2                	ld	s3,24(sp)
    8000193c:	6a42                	ld	s4,16(sp)
    8000193e:	6aa2                	ld	s5,8(sp)
    80001940:	6b02                	ld	s6,0(sp)
    80001942:	6121                	addi	sp,sp,64
    80001944:	8082                	ret
      panic("kalloc");
    80001946:	00007517          	auipc	a0,0x7
    8000194a:	89250513          	addi	a0,a0,-1902 # 800081d8 <digits+0x198>
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>

0000000080001956 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001956:	7139                	addi	sp,sp,-64
    80001958:	fc06                	sd	ra,56(sp)
    8000195a:	f822                	sd	s0,48(sp)
    8000195c:	f426                	sd	s1,40(sp)
    8000195e:	f04a                	sd	s2,32(sp)
    80001960:	ec4e                	sd	s3,24(sp)
    80001962:	e852                	sd	s4,16(sp)
    80001964:	e456                	sd	s5,8(sp)
    80001966:	e05a                	sd	s6,0(sp)
    80001968:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000196a:	00007597          	auipc	a1,0x7
    8000196e:	87658593          	addi	a1,a1,-1930 # 800081e0 <digits+0x1a0>
    80001972:	0000f517          	auipc	a0,0xf
    80001976:	1de50513          	addi	a0,a0,478 # 80010b50 <pid_lock>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	1cc080e7          	jalr	460(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001982:	00007597          	auipc	a1,0x7
    80001986:	86658593          	addi	a1,a1,-1946 # 800081e8 <digits+0x1a8>
    8000198a:	0000f517          	auipc	a0,0xf
    8000198e:	1de50513          	addi	a0,a0,478 # 80010b68 <wait_lock>
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	1b4080e7          	jalr	436(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000199a:	00010497          	auipc	s1,0x10
    8000199e:	e4648493          	addi	s1,s1,-442 # 800117e0 <proc>
  {
    initlock(&p->lock, "proc");
    800019a2:	00007b17          	auipc	s6,0x7
    800019a6:	856b0b13          	addi	s6,s6,-1962 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019aa:	8aa6                	mv	s5,s1
    800019ac:	00006a17          	auipc	s4,0x6
    800019b0:	654a0a13          	addi	s4,s4,1620 # 80008000 <etext>
    800019b4:	04000937          	lui	s2,0x4000
    800019b8:	197d                	addi	s2,s2,-1
    800019ba:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019bc:	00019997          	auipc	s3,0x19
    800019c0:	62498993          	addi	s3,s3,1572 # 8001afe0 <tickslock>
    initlock(&p->lock, "proc");
    800019c4:	85da                	mv	a1,s6
    800019c6:	8526                	mv	a0,s1
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	17e080e7          	jalr	382(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    800019d0:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019d4:	415487b3          	sub	a5,s1,s5
    800019d8:	8795                	srai	a5,a5,0x5
    800019da:	000a3703          	ld	a4,0(s4)
    800019de:	02e787b3          	mul	a5,a5,a4
    800019e2:	2785                	addiw	a5,a5,1
    800019e4:	00d7979b          	slliw	a5,a5,0xd
    800019e8:	40f907b3          	sub	a5,s2,a5
    800019ec:	e4bc                	sd	a5,72(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019ee:	26048493          	addi	s1,s1,608
    800019f2:	fd3499e3          	bne	s1,s3,800019c4 <procinit+0x6e>
  }
}
    800019f6:	70e2                	ld	ra,56(sp)
    800019f8:	7442                	ld	s0,48(sp)
    800019fa:	74a2                	ld	s1,40(sp)
    800019fc:	7902                	ld	s2,32(sp)
    800019fe:	69e2                	ld	s3,24(sp)
    80001a00:	6a42                	ld	s4,16(sp)
    80001a02:	6aa2                	ld	s5,8(sp)
    80001a04:	6b02                	ld	s6,0(sp)
    80001a06:	6121                	addi	sp,sp,64
    80001a08:	8082                	ret

0000000080001a0a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a10:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a12:	2501                	sext.w	a0,a0
    80001a14:	6422                	ld	s0,8(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret

0000000080001a1a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e422                	sd	s0,8(sp)
    80001a1e:	0800                	addi	s0,sp,16
    80001a20:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a26:	0000f517          	auipc	a0,0xf
    80001a2a:	15a50513          	addi	a0,a0,346 # 80010b80 <cpus>
    80001a2e:	953e                	add	a0,a0,a5
    80001a30:	6422                	ld	s0,8(sp)
    80001a32:	0141                	addi	sp,sp,16
    80001a34:	8082                	ret

0000000080001a36 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	1000                	addi	s0,sp,32
  push_off();
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	14a080e7          	jalr	330(ra) # 80000b8a <push_off>
    80001a48:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a4a:	2781                	sext.w	a5,a5
    80001a4c:	079e                	slli	a5,a5,0x7
    80001a4e:	0000f717          	auipc	a4,0xf
    80001a52:	10270713          	addi	a4,a4,258 # 80010b50 <pid_lock>
    80001a56:	97ba                	add	a5,a5,a4
    80001a58:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	1d0080e7          	jalr	464(ra) # 80000c2a <pop_off>
  return p;
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6105                	addi	sp,sp,32
    80001a6c:	8082                	ret

0000000080001a6e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a6e:	1141                	addi	sp,sp,-16
    80001a70:	e406                	sd	ra,8(sp)
    80001a72:	e022                	sd	s0,0(sp)
    80001a74:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a76:	00000097          	auipc	ra,0x0
    80001a7a:	fc0080e7          	jalr	-64(ra) # 80001a36 <myproc>
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	20c080e7          	jalr	524(ra) # 80000c8a <release>

  if (first)
    80001a86:	00007797          	auipc	a5,0x7
    80001a8a:	dda7a783          	lw	a5,-550(a5) # 80008860 <first.1>
    80001a8e:	eb89                	bnez	a5,80001aa0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a90:	00001097          	auipc	ra,0x1
    80001a94:	f30080e7          	jalr	-208(ra) # 800029c0 <usertrapret>
}
    80001a98:	60a2                	ld	ra,8(sp)
    80001a9a:	6402                	ld	s0,0(sp)
    80001a9c:	0141                	addi	sp,sp,16
    80001a9e:	8082                	ret
    first = 0;
    80001aa0:	00007797          	auipc	a5,0x7
    80001aa4:	dc07a023          	sw	zero,-576(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001aa8:	4505                	li	a0,1
    80001aaa:	00002097          	auipc	ra,0x2
    80001aae:	e7a080e7          	jalr	-390(ra) # 80003924 <fsinit>
    80001ab2:	bff9                	j	80001a90 <forkret+0x22>

0000000080001ab4 <allocpid>:
{
    80001ab4:	1101                	addi	sp,sp,-32
    80001ab6:	ec06                	sd	ra,24(sp)
    80001ab8:	e822                	sd	s0,16(sp)
    80001aba:	e426                	sd	s1,8(sp)
    80001abc:	e04a                	sd	s2,0(sp)
    80001abe:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac0:	0000f917          	auipc	s2,0xf
    80001ac4:	09090913          	addi	s2,s2,144 # 80010b50 <pid_lock>
    80001ac8:	854a                	mv	a0,s2
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	10c080e7          	jalr	268(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001ad2:	00007797          	auipc	a5,0x7
    80001ad6:	d9278793          	addi	a5,a5,-622 # 80008864 <nextpid>
    80001ada:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001adc:	0014871b          	addiw	a4,s1,1
    80001ae0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae2:	854a                	mv	a0,s2
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	1a6080e7          	jalr	422(ra) # 80000c8a <release>
}
    80001aec:	8526                	mv	a0,s1
    80001aee:	60e2                	ld	ra,24(sp)
    80001af0:	6442                	ld	s0,16(sp)
    80001af2:	64a2                	ld	s1,8(sp)
    80001af4:	6902                	ld	s2,0(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret

0000000080001afa <queue_swap>:
{
    80001afa:	1141                	addi	sp,sp,-16
    80001afc:	e422                	sd	s0,8(sp)
    80001afe:	0800                	addi	s0,sp,16
  for (int curr = q->front; curr != q->rear; curr = (curr + 1) % (NPROC + 1))
    80001b00:	415c                	lw	a5,4(a0)
    80001b02:	4510                	lw	a2,8(a0)
    80001b04:	02c78b63          	beq	a5,a2,80001b3a <queue_swap+0x40>
      q->arr[curr] = q->arr[(curr + 1) % (NPROC + 1)];
    80001b08:	04100813          	li	a6,65
    80001b0c:	a031                	j	80001b18 <queue_swap+0x1e>
  for (int curr = q->front; curr != q->rear; curr = (curr + 1) % (NPROC + 1))
    80001b0e:	2785                	addiw	a5,a5,1
    80001b10:	0307e7bb          	remw	a5,a5,a6
    80001b14:	02c78363          	beq	a5,a2,80001b3a <queue_swap+0x40>
    if (q->arr[curr]->pid == pid)
    80001b18:	00379713          	slli	a4,a5,0x3
    80001b1c:	972a                	add	a4,a4,a0
    80001b1e:	6b14                	ld	a3,16(a4)
    80001b20:	5a94                	lw	a3,48(a3)
    80001b22:	feb696e3          	bne	a3,a1,80001b0e <queue_swap+0x14>
      q->arr[curr] = q->arr[(curr + 1) % (NPROC + 1)];
    80001b26:	0017869b          	addiw	a3,a5,1
    80001b2a:	0306e6bb          	remw	a3,a3,a6
    80001b2e:	0689                	addi	a3,a3,2
    80001b30:	068e                	slli	a3,a3,0x3
    80001b32:	96aa                	add	a3,a3,a0
    80001b34:	6294                	ld	a3,0(a3)
    80001b36:	eb14                	sd	a3,16(a4)
    80001b38:	bfd9                	j	80001b0e <queue_swap+0x14>
  q->rear--;
    80001b3a:	367d                	addiw	a2,a2,-1
    80001b3c:	0006079b          	sext.w	a5,a2
  if (q->rear < 0)
    80001b40:	0007c963          	bltz	a5,80001b52 <queue_swap+0x58>
  q->rear--;
    80001b44:	c510                	sw	a2,8(a0)
  q->numitems--;
    80001b46:	455c                	lw	a5,12(a0)
    80001b48:	37fd                	addiw	a5,a5,-1
    80001b4a:	c55c                	sw	a5,12(a0)
}
    80001b4c:	6422                	ld	s0,8(sp)
    80001b4e:	0141                	addi	sp,sp,16
    80001b50:	8082                	ret
    q->rear = NPROC;
    80001b52:	04000793          	li	a5,64
    80001b56:	c51c                	sw	a5,8(a0)
    80001b58:	b7fd                	j	80001b46 <queue_swap+0x4c>

0000000080001b5a <proc_pagetable>:
{
    80001b5a:	1101                	addi	sp,sp,-32
    80001b5c:	ec06                	sd	ra,24(sp)
    80001b5e:	e822                	sd	s0,16(sp)
    80001b60:	e426                	sd	s1,8(sp)
    80001b62:	e04a                	sd	s2,0(sp)
    80001b64:	1000                	addi	s0,sp,32
    80001b66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	7c0080e7          	jalr	1984(ra) # 80001328 <uvmcreate>
    80001b70:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b72:	c121                	beqz	a0,80001bb2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b74:	4729                	li	a4,10
    80001b76:	00005697          	auipc	a3,0x5
    80001b7a:	48a68693          	addi	a3,a3,1162 # 80007000 <_trampoline>
    80001b7e:	6605                	lui	a2,0x1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	addi	a1,a1,-1
    80001b86:	05b2                	slli	a1,a1,0xc
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	516080e7          	jalr	1302(ra) # 8000109e <mappages>
    80001b90:	02054863          	bltz	a0,80001bc0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b94:	4719                	li	a4,6
    80001b96:	06093683          	ld	a3,96(s2)
    80001b9a:	6605                	lui	a2,0x1
    80001b9c:	020005b7          	lui	a1,0x2000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b6                	slli	a1,a1,0xd
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	4f8080e7          	jalr	1272(ra) # 8000109e <mappages>
    80001bae:	02054163          	bltz	a0,80001bd0 <proc_pagetable+0x76>
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret
    uvmfree(pagetable, 0);
    80001bc0:	4581                	li	a1,0
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	968080e7          	jalr	-1688(ra) # 8000152c <uvmfree>
    return 0;
    80001bcc:	4481                	li	s1,0
    80001bce:	b7d5                	j	80001bb2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bd0:	4681                	li	a3,0
    80001bd2:	4605                	li	a2,1
    80001bd4:	040005b7          	lui	a1,0x4000
    80001bd8:	15fd                	addi	a1,a1,-1
    80001bda:	05b2                	slli	a1,a1,0xc
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	686080e7          	jalr	1670(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001be6:	4581                	li	a1,0
    80001be8:	8526                	mv	a0,s1
    80001bea:	00000097          	auipc	ra,0x0
    80001bee:	942080e7          	jalr	-1726(ra) # 8000152c <uvmfree>
    return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	bf7d                	j	80001bb2 <proc_pagetable+0x58>

0000000080001bf6 <proc_freepagetable>:
{
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	e04a                	sd	s2,0(sp)
    80001c00:	1000                	addi	s0,sp,32
    80001c02:	84aa                	mv	s1,a0
    80001c04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c06:	4681                	li	a3,0
    80001c08:	4605                	li	a2,1
    80001c0a:	040005b7          	lui	a1,0x4000
    80001c0e:	15fd                	addi	a1,a1,-1
    80001c10:	05b2                	slli	a1,a1,0xc
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	652080e7          	jalr	1618(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c1a:	4681                	li	a3,0
    80001c1c:	4605                	li	a2,1
    80001c1e:	020005b7          	lui	a1,0x2000
    80001c22:	15fd                	addi	a1,a1,-1
    80001c24:	05b6                	slli	a1,a1,0xd
    80001c26:	8526                	mv	a0,s1
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	63c080e7          	jalr	1596(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c30:	85ca                	mv	a1,s2
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	8f8080e7          	jalr	-1800(ra) # 8000152c <uvmfree>
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6902                	ld	s2,0(sp)
    80001c44:	6105                	addi	sp,sp,32
    80001c46:	8082                	ret

0000000080001c48 <freeproc>:
{
    80001c48:	1101                	addi	sp,sp,-32
    80001c4a:	ec06                	sd	ra,24(sp)
    80001c4c:	e822                	sd	s0,16(sp)
    80001c4e:	e426                	sd	s1,8(sp)
    80001c50:	1000                	addi	s0,sp,32
    80001c52:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c54:	7128                	ld	a0,96(a0)
    80001c56:	c509                	beqz	a0,80001c60 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	d92080e7          	jalr	-622(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001c60:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001c64:	6ca8                	ld	a0,88(s1)
    80001c66:	c511                	beqz	a0,80001c72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c68:	68ac                	ld	a1,80(s1)
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f8c080e7          	jalr	-116(ra) # 80001bf6 <proc_freepagetable>
  p->pagetable = 0;
    80001c72:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c76:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001c7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c82:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c92:	0004ac23          	sw	zero,24(s1)
}
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6105                	addi	sp,sp,32
    80001c9e:	8082                	ret

0000000080001ca0 <allocproc>:
{
    80001ca0:	1101                	addi	sp,sp,-32
    80001ca2:	ec06                	sd	ra,24(sp)
    80001ca4:	e822                	sd	s0,16(sp)
    80001ca6:	e426                	sd	s1,8(sp)
    80001ca8:	e04a                	sd	s2,0(sp)
    80001caa:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001cac:	00010497          	auipc	s1,0x10
    80001cb0:	b3448493          	addi	s1,s1,-1228 # 800117e0 <proc>
    80001cb4:	00019917          	auipc	s2,0x19
    80001cb8:	32c90913          	addi	s2,s2,812 # 8001afe0 <tickslock>
    acquire(&p->lock);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	f18080e7          	jalr	-232(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001cc6:	4c9c                	lw	a5,24(s1)
    80001cc8:	cf81                	beqz	a5,80001ce0 <allocproc+0x40>
      release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	fbe080e7          	jalr	-66(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cd4:	26048493          	addi	s1,s1,608
    80001cd8:	ff2492e3          	bne	s1,s2,80001cbc <allocproc+0x1c>
  return 0;
    80001cdc:	4481                	li	s1,0
    80001cde:	a8d1                	j	80001db2 <allocproc+0x112>
  p->pid = allocpid();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	dd4080e7          	jalr	-556(ra) # 80001ab4 <allocpid>
    80001ce8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cea:	4785                	li	a5,1
    80001cec:	cc9c                	sw	a5,24(s1)
  p->cur_ticks=0;
    80001cee:	2004ae23          	sw	zero,540(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	df4080e7          	jalr	-524(ra) # 80000ae6 <kalloc>
    80001cfa:	892a                	mv	s2,a0
    80001cfc:	f0a8                	sd	a0,96(s1)
    80001cfe:	c169                	beqz	a0,80001dc0 <allocproc+0x120>
  p->readcallcount=0;
    80001d00:	0404a023          	sw	zero,64(s1)
  p->run_time = 0;
    80001d04:	2004b023          	sd	zero,512(s1)
  p->sleep_time = 0;
    80001d08:	2004b823          	sd	zero,528(s1)
  p->mlfq_priority = 0;
    80001d0c:	1a04bc23          	sd	zero,440(s1)
  p->queue_in_time = 0;
    80001d10:	1c04bc23          	sd	zero,472(s1)
  p->runs_till_now = 0;
    80001d14:	1c04b823          	sd	zero,464(s1)
    p->queue_run_time[i] = 0;
    80001d18:	1e04b023          	sd	zero,480(s1)
    80001d1c:	1e04b423          	sd	zero,488(s1)
    80001d20:	1e04b823          	sd	zero,496(s1)
    80001d24:	1e04bc23          	sd	zero,504(s1)
  p->age_queue[0] = -10;
    80001d28:	57d9                	li	a5,-10
    80001d2a:	22f4b823          	sd	a5,560(s1)
  p->age_queue[1] = 10;
    80001d2e:	47a9                	li	a5,10
    80001d30:	22f4bc23          	sd	a5,568(s1)
  p->age_queue[2] = 20;
    80001d34:	47d1                	li	a5,20
    80001d36:	24f4b023          	sd	a5,576(s1)
  p->age_queue[3] = 30;
    80001d3a:	47f9                	li	a5,30
    80001d3c:	24f4b423          	sd	a5,584(s1)
  p->wait_time = 0;
    80001d40:	1a04a223          	sw	zero,420(s1)
  p->quantums_left = 1;
    80001d44:	4785                	li	a5,1
    80001d46:	1cf4b423          	sd	a5,456(s1)
  p->pagetable = proc_pagetable(p);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	e0e080e7          	jalr	-498(ra) # 80001b5a <proc_pagetable>
    80001d54:	892a                	mv	s2,a0
    80001d56:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001d58:	c141                	beqz	a0,80001dd8 <allocproc+0x138>
  memset(&p->context, 0, sizeof(p->context));
    80001d5a:	07000613          	li	a2,112
    80001d5e:	4581                	li	a1,0
    80001d60:	06848513          	addi	a0,s1,104
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	f6e080e7          	jalr	-146(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d6c:	00000797          	auipc	a5,0x0
    80001d70:	d0278793          	addi	a5,a5,-766 # 80001a6e <forkret>
    80001d74:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d76:	64bc                	ld	a5,72(s1)
    80001d78:	6705                	lui	a4,0x1
    80001d7a:	97ba                	add	a5,a5,a4
    80001d7c:	f8bc                	sd	a5,112(s1)
  p->rtime = 0;
    80001d7e:	1604a823          	sw	zero,368(s1)
  p->etime = 0;
    80001d82:	1604ac23          	sw	zero,376(s1)
  p->ctime = ticks;
    80001d86:	00007797          	auipc	a5,0x7
    80001d8a:	b5a7a783          	lw	a5,-1190(a5) # 800088e0 <ticks>
    80001d8e:	16f4aa23          	sw	a5,372(s1)
  p->sigalarm = 0;
    80001d92:	1804a423          	sw	zero,392(s1)
  p->ticksn = 0;
    80001d96:	1604ae23          	sw	zero,380(s1)
  p->ticksp = 0;
    80001d9a:	1804a023          	sw	zero,384(s1)
  p->tickspa = 0;
    80001d9e:	1804a223          	sw	zero,388(s1)
  p->handler = 0;
    80001da2:	2404b823          	sd	zero,592(s1)
  p->is_sigalarm = 0;
    80001da6:	1804ac23          	sw	zero,408(s1)
  p->clockval = 0;
    80001daa:	1804ae23          	sw	zero,412(s1)
  p->completed_clockval = 0;
    80001dae:	1a04a023          	sw	zero,416(s1)
}
    80001db2:	8526                	mv	a0,s1
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6902                	ld	s2,0(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret
    freeproc(p);
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	e86080e7          	jalr	-378(ra) # 80001c48 <freeproc>
    release(&p->lock);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	ebe080e7          	jalr	-322(ra) # 80000c8a <release>
    return 0;
    80001dd4:	84ca                	mv	s1,s2
    80001dd6:	bff1                	j	80001db2 <allocproc+0x112>
    freeproc(p);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	e6e080e7          	jalr	-402(ra) # 80001c48 <freeproc>
    release(&p->lock);
    80001de2:	8526                	mv	a0,s1
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	ea6080e7          	jalr	-346(ra) # 80000c8a <release>
    return 0;
    80001dec:	84ca                	mv	s1,s2
    80001dee:	b7d1                	j	80001db2 <allocproc+0x112>

0000000080001df0 <userinit>:
{
    80001df0:	1101                	addi	sp,sp,-32
    80001df2:	ec06                	sd	ra,24(sp)
    80001df4:	e822                	sd	s0,16(sp)
    80001df6:	e426                	sd	s1,8(sp)
    80001df8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	ea6080e7          	jalr	-346(ra) # 80001ca0 <allocproc>
    80001e02:	84aa                	mv	s1,a0
  initproc = p;
    80001e04:	00007797          	auipc	a5,0x7
    80001e08:	aca7ba23          	sd	a0,-1324(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e0c:	03400613          	li	a2,52
    80001e10:	00007597          	auipc	a1,0x7
    80001e14:	a6058593          	addi	a1,a1,-1440 # 80008870 <initcode>
    80001e18:	6d28                	ld	a0,88(a0)
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	53c080e7          	jalr	1340(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001e22:	6785                	lui	a5,0x1
    80001e24:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e26:	70b8                	ld	a4,96(s1)
    80001e28:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e2c:	70b8                	ld	a4,96(s1)
    80001e2e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	00006597          	auipc	a1,0x6
    80001e36:	3ce58593          	addi	a1,a1,974 # 80008200 <digits+0x1c0>
    80001e3a:	16048513          	addi	a0,s1,352
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	fde080e7          	jalr	-34(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e46:	00006517          	auipc	a0,0x6
    80001e4a:	3ca50513          	addi	a0,a0,970 # 80008210 <digits+0x1d0>
    80001e4e:	00002097          	auipc	ra,0x2
    80001e52:	4f8080e7          	jalr	1272(ra) # 80004346 <namei>
    80001e56:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e5a:	478d                	li	a5,3
    80001e5c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e2a080e7          	jalr	-470(ra) # 80000c8a <release>
}
    80001e68:	60e2                	ld	ra,24(sp)
    80001e6a:	6442                	ld	s0,16(sp)
    80001e6c:	64a2                	ld	s1,8(sp)
    80001e6e:	6105                	addi	sp,sp,32
    80001e70:	8082                	ret

0000000080001e72 <growproc>:
{
    80001e72:	1101                	addi	sp,sp,-32
    80001e74:	ec06                	sd	ra,24(sp)
    80001e76:	e822                	sd	s0,16(sp)
    80001e78:	e426                	sd	s1,8(sp)
    80001e7a:	e04a                	sd	s2,0(sp)
    80001e7c:	1000                	addi	s0,sp,32
    80001e7e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	bb6080e7          	jalr	-1098(ra) # 80001a36 <myproc>
    80001e88:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e8a:	692c                	ld	a1,80(a0)
  if (n > 0)
    80001e8c:	01204c63          	bgtz	s2,80001ea4 <growproc+0x32>
  else if (n < 0)
    80001e90:	02094663          	bltz	s2,80001ebc <growproc+0x4a>
  p->sz = sz;
    80001e94:	e8ac                	sd	a1,80(s1)
  return 0;
    80001e96:	4501                	li	a0,0
}
    80001e98:	60e2                	ld	ra,24(sp)
    80001e9a:	6442                	ld	s0,16(sp)
    80001e9c:	64a2                	ld	s1,8(sp)
    80001e9e:	6902                	ld	s2,0(sp)
    80001ea0:	6105                	addi	sp,sp,32
    80001ea2:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ea4:	4691                	li	a3,4
    80001ea6:	00b90633          	add	a2,s2,a1
    80001eaa:	6d28                	ld	a0,88(a0)
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	564080e7          	jalr	1380(ra) # 80001410 <uvmalloc>
    80001eb4:	85aa                	mv	a1,a0
    80001eb6:	fd79                	bnez	a0,80001e94 <growproc+0x22>
      return -1;
    80001eb8:	557d                	li	a0,-1
    80001eba:	bff9                	j	80001e98 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ebc:	00b90633          	add	a2,s2,a1
    80001ec0:	6d28                	ld	a0,88(a0)
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	506080e7          	jalr	1286(ra) # 800013c8 <uvmdealloc>
    80001eca:	85aa                	mv	a1,a0
    80001ecc:	b7e1                	j	80001e94 <growproc+0x22>

0000000080001ece <fork>:
{
    80001ece:	7139                	addi	sp,sp,-64
    80001ed0:	fc06                	sd	ra,56(sp)
    80001ed2:	f822                	sd	s0,48(sp)
    80001ed4:	f426                	sd	s1,40(sp)
    80001ed6:	f04a                	sd	s2,32(sp)
    80001ed8:	ec4e                	sd	s3,24(sp)
    80001eda:	e852                	sd	s4,16(sp)
    80001edc:	e456                	sd	s5,8(sp)
    80001ede:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	b56080e7          	jalr	-1194(ra) # 80001a36 <myproc>
    80001ee8:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	db6080e7          	jalr	-586(ra) # 80001ca0 <allocproc>
    80001ef2:	10050c63          	beqz	a0,8000200a <fork+0x13c>
    80001ef6:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ef8:	050ab603          	ld	a2,80(s5)
    80001efc:	6d2c                	ld	a1,88(a0)
    80001efe:	058ab503          	ld	a0,88(s5)
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	662080e7          	jalr	1634(ra) # 80001564 <uvmcopy>
    80001f0a:	04054863          	bltz	a0,80001f5a <fork+0x8c>
  np->sz = p->sz;
    80001f0e:	050ab783          	ld	a5,80(s5)
    80001f12:	04fa3823          	sd	a5,80(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f16:	060ab683          	ld	a3,96(s5)
    80001f1a:	87b6                	mv	a5,a3
    80001f1c:	060a3703          	ld	a4,96(s4)
    80001f20:	12068693          	addi	a3,a3,288
    80001f24:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f28:	6788                	ld	a0,8(a5)
    80001f2a:	6b8c                	ld	a1,16(a5)
    80001f2c:	6f90                	ld	a2,24(a5)
    80001f2e:	01073023          	sd	a6,0(a4)
    80001f32:	e708                	sd	a0,8(a4)
    80001f34:	eb0c                	sd	a1,16(a4)
    80001f36:	ef10                	sd	a2,24(a4)
    80001f38:	02078793          	addi	a5,a5,32
    80001f3c:	02070713          	addi	a4,a4,32
    80001f40:	fed792e3          	bne	a5,a3,80001f24 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f44:	060a3783          	ld	a5,96(s4)
    80001f48:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f4c:	0d8a8493          	addi	s1,s5,216
    80001f50:	0d8a0913          	addi	s2,s4,216
    80001f54:	158a8993          	addi	s3,s5,344
    80001f58:	a00d                	j	80001f7a <fork+0xac>
    freeproc(np);
    80001f5a:	8552                	mv	a0,s4
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	cec080e7          	jalr	-788(ra) # 80001c48 <freeproc>
    release(&np->lock);
    80001f64:	8552                	mv	a0,s4
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d24080e7          	jalr	-732(ra) # 80000c8a <release>
    return -1;
    80001f6e:	597d                	li	s2,-1
    80001f70:	a059                	j	80001ff6 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001f72:	04a1                	addi	s1,s1,8
    80001f74:	0921                	addi	s2,s2,8
    80001f76:	01348b63          	beq	s1,s3,80001f8c <fork+0xbe>
    if (p->ofile[i])
    80001f7a:	6088                	ld	a0,0(s1)
    80001f7c:	d97d                	beqz	a0,80001f72 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f7e:	00003097          	auipc	ra,0x3
    80001f82:	a5e080e7          	jalr	-1442(ra) # 800049dc <filedup>
    80001f86:	00a93023          	sd	a0,0(s2)
    80001f8a:	b7e5                	j	80001f72 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f8c:	158ab503          	ld	a0,344(s5)
    80001f90:	00002097          	auipc	ra,0x2
    80001f94:	bd2080e7          	jalr	-1070(ra) # 80003b62 <idup>
    80001f98:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f9c:	4641                	li	a2,16
    80001f9e:	160a8593          	addi	a1,s5,352
    80001fa2:	160a0513          	addi	a0,s4,352
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	e76080e7          	jalr	-394(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001fae:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fb2:	8552                	mv	a0,s4
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	cd6080e7          	jalr	-810(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001fbc:	0000f497          	auipc	s1,0xf
    80001fc0:	bac48493          	addi	s1,s1,-1108 # 80010b68 <wait_lock>
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001fce:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cb6080e7          	jalr	-842(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001fdc:	8552                	mv	a0,s4
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	bf8080e7          	jalr	-1032(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001fe6:	478d                	li	a5,3
    80001fe8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fec:	8552                	mv	a0,s4
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	c9c080e7          	jalr	-868(ra) # 80000c8a <release>
}
    80001ff6:	854a                	mv	a0,s2
    80001ff8:	70e2                	ld	ra,56(sp)
    80001ffa:	7442                	ld	s0,48(sp)
    80001ffc:	74a2                	ld	s1,40(sp)
    80001ffe:	7902                	ld	s2,32(sp)
    80002000:	69e2                	ld	s3,24(sp)
    80002002:	6a42                	ld	s4,16(sp)
    80002004:	6aa2                	ld	s5,8(sp)
    80002006:	6121                	addi	sp,sp,64
    80002008:	8082                	ret
    return -1;
    8000200a:	597d                	li	s2,-1
    8000200c:	b7ed                	j	80001ff6 <fork+0x128>

000000008000200e <scheduler>:
{
    8000200e:	7139                	addi	sp,sp,-64
    80002010:	fc06                	sd	ra,56(sp)
    80002012:	f822                	sd	s0,48(sp)
    80002014:	f426                	sd	s1,40(sp)
    80002016:	f04a                	sd	s2,32(sp)
    80002018:	ec4e                	sd	s3,24(sp)
    8000201a:	e852                	sd	s4,16(sp)
    8000201c:	e456                	sd	s5,8(sp)
    8000201e:	e05a                	sd	s6,0(sp)
    80002020:	0080                	addi	s0,sp,64
    80002022:	8792                	mv	a5,tp
  int id = r_tp();
    80002024:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002026:	00779a93          	slli	s5,a5,0x7
    8000202a:	0000f717          	auipc	a4,0xf
    8000202e:	b2670713          	addi	a4,a4,-1242 # 80010b50 <pid_lock>
    80002032:	9756                	add	a4,a4,s5
    80002034:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002038:	0000f717          	auipc	a4,0xf
    8000203c:	b5070713          	addi	a4,a4,-1200 # 80010b88 <cpus+0x8>
    80002040:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002042:	498d                	li	s3,3
        p->state = RUNNING;
    80002044:	4b11                	li	s6,4
        c->proc = p;
    80002046:	079e                	slli	a5,a5,0x7
    80002048:	0000fa17          	auipc	s4,0xf
    8000204c:	b08a0a13          	addi	s4,s4,-1272 # 80010b50 <pid_lock>
    80002050:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002052:	00019917          	auipc	s2,0x19
    80002056:	f8e90913          	addi	s2,s2,-114 # 8001afe0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000205a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000205e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002062:	10079073          	csrw	sstatus,a5
    80002066:	0000f497          	auipc	s1,0xf
    8000206a:	77a48493          	addi	s1,s1,1914 # 800117e0 <proc>
    8000206e:	a811                	j	80002082 <scheduler+0x74>
      release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c18080e7          	jalr	-1000(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000207a:	26048493          	addi	s1,s1,608
    8000207e:	fd248ee3          	beq	s1,s2,8000205a <scheduler+0x4c>
      acquire(&p->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b52080e7          	jalr	-1198(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    8000208c:	4c9c                	lw	a5,24(s1)
    8000208e:	ff3791e3          	bne	a5,s3,80002070 <scheduler+0x62>
        p->state = RUNNING;
    80002092:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002096:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000209a:	06848593          	addi	a1,s1,104
    8000209e:	8556                	mv	a0,s5
    800020a0:	00001097          	auipc	ra,0x1
    800020a4:	876080e7          	jalr	-1930(ra) # 80002916 <swtch>
        c->proc = 0;
    800020a8:	020a3823          	sd	zero,48(s4)
    800020ac:	b7d1                	j	80002070 <scheduler+0x62>

00000000800020ae <sched>:
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	97a080e7          	jalr	-1670(ra) # 80001a36 <myproc>
    800020c4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	a96080e7          	jalr	-1386(ra) # 80000b5c <holding>
    800020ce:	c93d                	beqz	a0,80002144 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020d2:	2781                	sext.w	a5,a5
    800020d4:	079e                	slli	a5,a5,0x7
    800020d6:	0000f717          	auipc	a4,0xf
    800020da:	a7a70713          	addi	a4,a4,-1414 # 80010b50 <pid_lock>
    800020de:	97ba                	add	a5,a5,a4
    800020e0:	0a87a703          	lw	a4,168(a5)
    800020e4:	4785                	li	a5,1
    800020e6:	06f71763          	bne	a4,a5,80002154 <sched+0xa6>
  if (p->state == RUNNING)
    800020ea:	4c98                	lw	a4,24(s1)
    800020ec:	4791                	li	a5,4
    800020ee:	06f70b63          	beq	a4,a5,80002164 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f6:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020f8:	efb5                	bnez	a5,80002174 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020fc:	0000f917          	auipc	s2,0xf
    80002100:	a5490913          	addi	s2,s2,-1452 # 80010b50 <pid_lock>
    80002104:	2781                	sext.w	a5,a5
    80002106:	079e                	slli	a5,a5,0x7
    80002108:	97ca                	add	a5,a5,s2
    8000210a:	0ac7a983          	lw	s3,172(a5)
    8000210e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	0000f597          	auipc	a1,0xf
    80002118:	a7458593          	addi	a1,a1,-1420 # 80010b88 <cpus+0x8>
    8000211c:	95be                	add	a1,a1,a5
    8000211e:	06848513          	addi	a0,s1,104
    80002122:	00000097          	auipc	ra,0x0
    80002126:	7f4080e7          	jalr	2036(ra) # 80002916 <swtch>
    8000212a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	97ca                	add	a5,a5,s2
    80002132:	0b37a623          	sw	s3,172(a5)
}
    80002136:	70a2                	ld	ra,40(sp)
    80002138:	7402                	ld	s0,32(sp)
    8000213a:	64e2                	ld	s1,24(sp)
    8000213c:	6942                	ld	s2,16(sp)
    8000213e:	69a2                	ld	s3,8(sp)
    80002140:	6145                	addi	sp,sp,48
    80002142:	8082                	ret
    panic("sched p->lock");
    80002144:	00006517          	auipc	a0,0x6
    80002148:	0d450513          	addi	a0,a0,212 # 80008218 <digits+0x1d8>
    8000214c:	ffffe097          	auipc	ra,0xffffe
    80002150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>
    panic("sched locks");
    80002154:	00006517          	auipc	a0,0x6
    80002158:	0d450513          	addi	a0,a0,212 # 80008228 <digits+0x1e8>
    8000215c:	ffffe097          	auipc	ra,0xffffe
    80002160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    panic("sched running");
    80002164:	00006517          	auipc	a0,0x6
    80002168:	0d450513          	addi	a0,a0,212 # 80008238 <digits+0x1f8>
    8000216c:	ffffe097          	auipc	ra,0xffffe
    80002170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	0d450513          	addi	a0,a0,212 # 80008248 <digits+0x208>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>

0000000080002184 <yield>:
{
    80002184:	1101                	addi	sp,sp,-32
    80002186:	ec06                	sd	ra,24(sp)
    80002188:	e822                	sd	s0,16(sp)
    8000218a:	e426                	sd	s1,8(sp)
    8000218c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	8a8080e7          	jalr	-1880(ra) # 80001a36 <myproc>
    80002196:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a3e080e7          	jalr	-1474(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800021a0:	478d                	li	a5,3
    800021a2:	cc9c                	sw	a5,24(s1)
  sched();
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	f0a080e7          	jalr	-246(ra) # 800020ae <sched>
  release(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	adc080e7          	jalr	-1316(ra) # 80000c8a <release>
}
    800021b6:	60e2                	ld	ra,24(sp)
    800021b8:	6442                	ld	s0,16(sp)
    800021ba:	64a2                	ld	s1,8(sp)
    800021bc:	6105                	addi	sp,sp,32
    800021be:	8082                	ret

00000000800021c0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021c0:	7179                	addi	sp,sp,-48
    800021c2:	f406                	sd	ra,40(sp)
    800021c4:	f022                	sd	s0,32(sp)
    800021c6:	ec26                	sd	s1,24(sp)
    800021c8:	e84a                	sd	s2,16(sp)
    800021ca:	e44e                	sd	s3,8(sp)
    800021cc:	1800                	addi	s0,sp,48
    800021ce:	89aa                	mv	s3,a0
    800021d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	864080e7          	jalr	-1948(ra) # 80001a36 <myproc>
    800021da:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	9fa080e7          	jalr	-1542(ra) # 80000bd6 <acquire>
  release(lk);
    800021e4:	854a                	mv	a0,s2
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	aa4080e7          	jalr	-1372(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021ee:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021f2:	4789                	li	a5,2
    800021f4:	cc9c                	sw	a5,24(s1)

  sched();
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	eb8080e7          	jalr	-328(ra) # 800020ae <sched>

  // Tidy up.
  p->chan = 0;
    800021fe:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a86080e7          	jalr	-1402(ra) # 80000c8a <release>
  acquire(lk);
    8000220c:	854a                	mv	a0,s2
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	9c8080e7          	jalr	-1592(ra) # 80000bd6 <acquire>
}
    80002216:	70a2                	ld	ra,40(sp)
    80002218:	7402                	ld	s0,32(sp)
    8000221a:	64e2                	ld	s1,24(sp)
    8000221c:	6942                	ld	s2,16(sp)
    8000221e:	69a2                	ld	s3,8(sp)
    80002220:	6145                	addi	sp,sp,48
    80002222:	8082                	ret

0000000080002224 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002224:	7139                	addi	sp,sp,-64
    80002226:	fc06                	sd	ra,56(sp)
    80002228:	f822                	sd	s0,48(sp)
    8000222a:	f426                	sd	s1,40(sp)
    8000222c:	f04a                	sd	s2,32(sp)
    8000222e:	ec4e                	sd	s3,24(sp)
    80002230:	e852                	sd	s4,16(sp)
    80002232:	e456                	sd	s5,8(sp)
    80002234:	0080                	addi	s0,sp,64
    80002236:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002238:	0000f497          	auipc	s1,0xf
    8000223c:	5a848493          	addi	s1,s1,1448 # 800117e0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002240:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002242:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002244:	00019917          	auipc	s2,0x19
    80002248:	d9c90913          	addi	s2,s2,-612 # 8001afe0 <tickslock>
    8000224c:	a811                	j	80002260 <wakeup+0x3c>
          enqueue(&MLFQ[p->mlfq_priority], p);
          p->wait_time = 0;
        }
#endif
      }
      release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a3a080e7          	jalr	-1478(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002258:	26048493          	addi	s1,s1,608
    8000225c:	03248663          	beq	s1,s2,80002288 <wakeup+0x64>
    if (p != myproc())
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	7d6080e7          	jalr	2006(ra) # 80001a36 <myproc>
    80002268:	fea488e3          	beq	s1,a0,80002258 <wakeup+0x34>
      acquire(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002276:	4c9c                	lw	a5,24(s1)
    80002278:	fd379be3          	bne	a5,s3,8000224e <wakeup+0x2a>
    8000227c:	709c                	ld	a5,32(s1)
    8000227e:	fd4798e3          	bne	a5,s4,8000224e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002282:	0154ac23          	sw	s5,24(s1)
    80002286:	b7e1                	j	8000224e <wakeup+0x2a>
    }
  }
}
    80002288:	70e2                	ld	ra,56(sp)
    8000228a:	7442                	ld	s0,48(sp)
    8000228c:	74a2                	ld	s1,40(sp)
    8000228e:	7902                	ld	s2,32(sp)
    80002290:	69e2                	ld	s3,24(sp)
    80002292:	6a42                	ld	s4,16(sp)
    80002294:	6aa2                	ld	s5,8(sp)
    80002296:	6121                	addi	sp,sp,64
    80002298:	8082                	ret

000000008000229a <reparent>:
{
    8000229a:	7179                	addi	sp,sp,-48
    8000229c:	f406                	sd	ra,40(sp)
    8000229e:	f022                	sd	s0,32(sp)
    800022a0:	ec26                	sd	s1,24(sp)
    800022a2:	e84a                	sd	s2,16(sp)
    800022a4:	e44e                	sd	s3,8(sp)
    800022a6:	e052                	sd	s4,0(sp)
    800022a8:	1800                	addi	s0,sp,48
    800022aa:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ac:	0000f497          	auipc	s1,0xf
    800022b0:	53448493          	addi	s1,s1,1332 # 800117e0 <proc>
      pp->parent = initproc;
    800022b4:	00006a17          	auipc	s4,0x6
    800022b8:	624a0a13          	addi	s4,s4,1572 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022bc:	00019997          	auipc	s3,0x19
    800022c0:	d2498993          	addi	s3,s3,-732 # 8001afe0 <tickslock>
    800022c4:	a029                	j	800022ce <reparent+0x34>
    800022c6:	26048493          	addi	s1,s1,608
    800022ca:	01348d63          	beq	s1,s3,800022e4 <reparent+0x4a>
    if (pp->parent == p)
    800022ce:	7c9c                	ld	a5,56(s1)
    800022d0:	ff279be3          	bne	a5,s2,800022c6 <reparent+0x2c>
      pp->parent = initproc;
    800022d4:	000a3503          	ld	a0,0(s4)
    800022d8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022da:	00000097          	auipc	ra,0x0
    800022de:	f4a080e7          	jalr	-182(ra) # 80002224 <wakeup>
    800022e2:	b7d5                	j	800022c6 <reparent+0x2c>
}
    800022e4:	70a2                	ld	ra,40(sp)
    800022e6:	7402                	ld	s0,32(sp)
    800022e8:	64e2                	ld	s1,24(sp)
    800022ea:	6942                	ld	s2,16(sp)
    800022ec:	69a2                	ld	s3,8(sp)
    800022ee:	6a02                	ld	s4,0(sp)
    800022f0:	6145                	addi	sp,sp,48
    800022f2:	8082                	ret

00000000800022f4 <exit>:
{
    800022f4:	7179                	addi	sp,sp,-48
    800022f6:	f406                	sd	ra,40(sp)
    800022f8:	f022                	sd	s0,32(sp)
    800022fa:	ec26                	sd	s1,24(sp)
    800022fc:	e84a                	sd	s2,16(sp)
    800022fe:	e44e                	sd	s3,8(sp)
    80002300:	e052                	sd	s4,0(sp)
    80002302:	1800                	addi	s0,sp,48
    80002304:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	730080e7          	jalr	1840(ra) # 80001a36 <myproc>
    8000230e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002310:	00006797          	auipc	a5,0x6
    80002314:	5c87b783          	ld	a5,1480(a5) # 800088d8 <initproc>
    80002318:	0d850493          	addi	s1,a0,216
    8000231c:	15850913          	addi	s2,a0,344
    80002320:	02a79363          	bne	a5,a0,80002346 <exit+0x52>
    panic("init exiting");
    80002324:	00006517          	auipc	a0,0x6
    80002328:	f3c50513          	addi	a0,a0,-196 # 80008260 <digits+0x220>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	212080e7          	jalr	530(ra) # 8000053e <panic>
      fileclose(f);
    80002334:	00002097          	auipc	ra,0x2
    80002338:	6fa080e7          	jalr	1786(ra) # 80004a2e <fileclose>
      p->ofile[fd] = 0;
    8000233c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002340:	04a1                	addi	s1,s1,8
    80002342:	01248563          	beq	s1,s2,8000234c <exit+0x58>
    if (p->ofile[fd])
    80002346:	6088                	ld	a0,0(s1)
    80002348:	f575                	bnez	a0,80002334 <exit+0x40>
    8000234a:	bfdd                	j	80002340 <exit+0x4c>
  begin_op();
    8000234c:	00002097          	auipc	ra,0x2
    80002350:	216080e7          	jalr	534(ra) # 80004562 <begin_op>
  iput(p->cwd);
    80002354:	1589b503          	ld	a0,344(s3)
    80002358:	00002097          	auipc	ra,0x2
    8000235c:	a02080e7          	jalr	-1534(ra) # 80003d5a <iput>
  end_op();
    80002360:	00002097          	auipc	ra,0x2
    80002364:	282080e7          	jalr	642(ra) # 800045e2 <end_op>
  p->cwd = 0;
    80002368:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000236c:	0000e497          	auipc	s1,0xe
    80002370:	7fc48493          	addi	s1,s1,2044 # 80010b68 <wait_lock>
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	860080e7          	jalr	-1952(ra) # 80000bd6 <acquire>
  reparent(p);
    8000237e:	854e                	mv	a0,s3
    80002380:	00000097          	auipc	ra,0x0
    80002384:	f1a080e7          	jalr	-230(ra) # 8000229a <reparent>
  wakeup(p->parent);
    80002388:	0389b503          	ld	a0,56(s3)
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	e98080e7          	jalr	-360(ra) # 80002224 <wakeup>
  acquire(&p->lock);
    80002394:	854e                	mv	a0,s3
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	840080e7          	jalr	-1984(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000239e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023a2:	4795                	li	a5,5
    800023a4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800023a8:	00006797          	auipc	a5,0x6
    800023ac:	5387a783          	lw	a5,1336(a5) # 800088e0 <ticks>
    800023b0:	16f9ac23          	sw	a5,376(s3)
  release(&wait_lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
  sched();
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	cf0080e7          	jalr	-784(ra) # 800020ae <sched>
  panic("zombie exit");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	eaa50513          	addi	a0,a0,-342 # 80008270 <digits+0x230>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800023d6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023d6:	7179                	addi	sp,sp,-48
    800023d8:	f406                	sd	ra,40(sp)
    800023da:	f022                	sd	s0,32(sp)
    800023dc:	ec26                	sd	s1,24(sp)
    800023de:	e84a                	sd	s2,16(sp)
    800023e0:	e44e                	sd	s3,8(sp)
    800023e2:	1800                	addi	s0,sp,48
    800023e4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023e6:	0000f497          	auipc	s1,0xf
    800023ea:	3fa48493          	addi	s1,s1,1018 # 800117e0 <proc>
    800023ee:	00019997          	auipc	s3,0x19
    800023f2:	bf298993          	addi	s3,s3,-1038 # 8001afe0 <tickslock>
  {
    acquire(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002400:	589c                	lw	a5,48(s1)
    80002402:	01278d63          	beq	a5,s2,8000241c <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002410:	26048493          	addi	s1,s1,608
    80002414:	ff3491e3          	bne	s1,s3,800023f6 <kill+0x20>
  }
  return -1;
    80002418:	557d                	li	a0,-1
    8000241a:	a829                	j	80002434 <kill+0x5e>
      p->killed = 1;
    8000241c:	4785                	li	a5,1
    8000241e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002420:	4c98                	lw	a4,24(s1)
    80002422:	4789                	li	a5,2
    80002424:	00f70f63          	beq	a4,a5,80002442 <kill+0x6c>
      release(&p->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return 0;
    80002432:	4501                	li	a0,0
}
    80002434:	70a2                	ld	ra,40(sp)
    80002436:	7402                	ld	s0,32(sp)
    80002438:	64e2                	ld	s1,24(sp)
    8000243a:	6942                	ld	s2,16(sp)
    8000243c:	69a2                	ld	s3,8(sp)
    8000243e:	6145                	addi	sp,sp,48
    80002440:	8082                	ret
        p->state = RUNNABLE;
    80002442:	478d                	li	a5,3
    80002444:	cc9c                	sw	a5,24(s1)
    80002446:	b7cd                	j	80002428 <kill+0x52>

0000000080002448 <setkilled>:

void setkilled(struct proc *p)
{
    80002448:	1101                	addi	sp,sp,-32
    8000244a:	ec06                	sd	ra,24(sp)
    8000244c:	e822                	sd	s0,16(sp)
    8000244e:	e426                	sd	s1,8(sp)
    80002450:	1000                	addi	s0,sp,32
    80002452:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	782080e7          	jalr	1922(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000245c:	4785                	li	a5,1
    8000245e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	828080e7          	jalr	-2008(ra) # 80000c8a <release>
}
    8000246a:	60e2                	ld	ra,24(sp)
    8000246c:	6442                	ld	s0,16(sp)
    8000246e:	64a2                	ld	s1,8(sp)
    80002470:	6105                	addi	sp,sp,32
    80002472:	8082                	ret

0000000080002474 <killed>:

int killed(struct proc *p)
{
    80002474:	1101                	addi	sp,sp,-32
    80002476:	ec06                	sd	ra,24(sp)
    80002478:	e822                	sd	s0,16(sp)
    8000247a:	e426                	sd	s1,8(sp)
    8000247c:	e04a                	sd	s2,0(sp)
    8000247e:	1000                	addi	s0,sp,32
    80002480:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	754080e7          	jalr	1876(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000248a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	7fa080e7          	jalr	2042(ra) # 80000c8a <release>
  return k;
}
    80002498:	854a                	mv	a0,s2
    8000249a:	60e2                	ld	ra,24(sp)
    8000249c:	6442                	ld	s0,16(sp)
    8000249e:	64a2                	ld	s1,8(sp)
    800024a0:	6902                	ld	s2,0(sp)
    800024a2:	6105                	addi	sp,sp,32
    800024a4:	8082                	ret

00000000800024a6 <wait>:
{
    800024a6:	715d                	addi	sp,sp,-80
    800024a8:	e486                	sd	ra,72(sp)
    800024aa:	e0a2                	sd	s0,64(sp)
    800024ac:	fc26                	sd	s1,56(sp)
    800024ae:	f84a                	sd	s2,48(sp)
    800024b0:	f44e                	sd	s3,40(sp)
    800024b2:	f052                	sd	s4,32(sp)
    800024b4:	ec56                	sd	s5,24(sp)
    800024b6:	e85a                	sd	s6,16(sp)
    800024b8:	e45e                	sd	s7,8(sp)
    800024ba:	e062                	sd	s8,0(sp)
    800024bc:	0880                	addi	s0,sp,80
    800024be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	576080e7          	jalr	1398(ra) # 80001a36 <myproc>
    800024c8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024ca:	0000e517          	auipc	a0,0xe
    800024ce:	69e50513          	addi	a0,a0,1694 # 80010b68 <wait_lock>
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	704080e7          	jalr	1796(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024da:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024dc:	4a15                	li	s4,5
        havekids = 1;
    800024de:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024e0:	00019997          	auipc	s3,0x19
    800024e4:	b0098993          	addi	s3,s3,-1280 # 8001afe0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024e8:	0000ec17          	auipc	s8,0xe
    800024ec:	680c0c13          	addi	s8,s8,1664 # 80010b68 <wait_lock>
    havekids = 0;
    800024f0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024f2:	0000f497          	auipc	s1,0xf
    800024f6:	2ee48493          	addi	s1,s1,750 # 800117e0 <proc>
    800024fa:	a0bd                	j	80002568 <wait+0xc2>
          pid = pp->pid;
    800024fc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002500:	000b0e63          	beqz	s6,8000251c <wait+0x76>
    80002504:	4691                	li	a3,4
    80002506:	02c48613          	addi	a2,s1,44
    8000250a:	85da                	mv	a1,s6
    8000250c:	05893503          	ld	a0,88(s2)
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	158080e7          	jalr	344(ra) # 80001668 <copyout>
    80002518:	02054563          	bltz	a0,80002542 <wait+0x9c>
          freeproc(pp);
    8000251c:	8526                	mv	a0,s1
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	72a080e7          	jalr	1834(ra) # 80001c48 <freeproc>
          release(&pp->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
          release(&wait_lock);
    80002530:	0000e517          	auipc	a0,0xe
    80002534:	63850513          	addi	a0,a0,1592 # 80010b68 <wait_lock>
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	752080e7          	jalr	1874(ra) # 80000c8a <release>
          return pid;
    80002540:	a0b5                	j	800025ac <wait+0x106>
            release(&pp->lock);
    80002542:	8526                	mv	a0,s1
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	746080e7          	jalr	1862(ra) # 80000c8a <release>
            release(&wait_lock);
    8000254c:	0000e517          	auipc	a0,0xe
    80002550:	61c50513          	addi	a0,a0,1564 # 80010b68 <wait_lock>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	736080e7          	jalr	1846(ra) # 80000c8a <release>
            return -1;
    8000255c:	59fd                	li	s3,-1
    8000255e:	a0b9                	j	800025ac <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002560:	26048493          	addi	s1,s1,608
    80002564:	03348463          	beq	s1,s3,8000258c <wait+0xe6>
      if (pp->parent == p)
    80002568:	7c9c                	ld	a5,56(s1)
    8000256a:	ff279be3          	bne	a5,s2,80002560 <wait+0xba>
        acquire(&pp->lock);
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	666080e7          	jalr	1638(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002578:	4c9c                	lw	a5,24(s1)
    8000257a:	f94781e3          	beq	a5,s4,800024fc <wait+0x56>
        release(&pp->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	70a080e7          	jalr	1802(ra) # 80000c8a <release>
        havekids = 1;
    80002588:	8756                	mv	a4,s5
    8000258a:	bfd9                	j	80002560 <wait+0xba>
    if (!havekids || killed(p))
    8000258c:	c719                	beqz	a4,8000259a <wait+0xf4>
    8000258e:	854a                	mv	a0,s2
    80002590:	00000097          	auipc	ra,0x0
    80002594:	ee4080e7          	jalr	-284(ra) # 80002474 <killed>
    80002598:	c51d                	beqz	a0,800025c6 <wait+0x120>
      release(&wait_lock);
    8000259a:	0000e517          	auipc	a0,0xe
    8000259e:	5ce50513          	addi	a0,a0,1486 # 80010b68 <wait_lock>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6e8080e7          	jalr	1768(ra) # 80000c8a <release>
      return -1;
    800025aa:	59fd                	li	s3,-1
}
    800025ac:	854e                	mv	a0,s3
    800025ae:	60a6                	ld	ra,72(sp)
    800025b0:	6406                	ld	s0,64(sp)
    800025b2:	74e2                	ld	s1,56(sp)
    800025b4:	7942                	ld	s2,48(sp)
    800025b6:	79a2                	ld	s3,40(sp)
    800025b8:	7a02                	ld	s4,32(sp)
    800025ba:	6ae2                	ld	s5,24(sp)
    800025bc:	6b42                	ld	s6,16(sp)
    800025be:	6ba2                	ld	s7,8(sp)
    800025c0:	6c02                	ld	s8,0(sp)
    800025c2:	6161                	addi	sp,sp,80
    800025c4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025c6:	85e2                	mv	a1,s8
    800025c8:	854a                	mv	a0,s2
    800025ca:	00000097          	auipc	ra,0x0
    800025ce:	bf6080e7          	jalr	-1034(ra) # 800021c0 <sleep>
    havekids = 0;
    800025d2:	bf39                	j	800024f0 <wait+0x4a>

00000000800025d4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025d4:	7179                	addi	sp,sp,-48
    800025d6:	f406                	sd	ra,40(sp)
    800025d8:	f022                	sd	s0,32(sp)
    800025da:	ec26                	sd	s1,24(sp)
    800025dc:	e84a                	sd	s2,16(sp)
    800025de:	e44e                	sd	s3,8(sp)
    800025e0:	e052                	sd	s4,0(sp)
    800025e2:	1800                	addi	s0,sp,48
    800025e4:	84aa                	mv	s1,a0
    800025e6:	892e                	mv	s2,a1
    800025e8:	89b2                	mv	s3,a2
    800025ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	44a080e7          	jalr	1098(ra) # 80001a36 <myproc>
  if (user_dst)
    800025f4:	c08d                	beqz	s1,80002616 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800025f6:	86d2                	mv	a3,s4
    800025f8:	864e                	mv	a2,s3
    800025fa:	85ca                	mv	a1,s2
    800025fc:	6d28                	ld	a0,88(a0)
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	06a080e7          	jalr	106(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002606:	70a2                	ld	ra,40(sp)
    80002608:	7402                	ld	s0,32(sp)
    8000260a:	64e2                	ld	s1,24(sp)
    8000260c:	6942                	ld	s2,16(sp)
    8000260e:	69a2                	ld	s3,8(sp)
    80002610:	6a02                	ld	s4,0(sp)
    80002612:	6145                	addi	sp,sp,48
    80002614:	8082                	ret
    memmove((char *)dst, src, len);
    80002616:	000a061b          	sext.w	a2,s4
    8000261a:	85ce                	mv	a1,s3
    8000261c:	854a                	mv	a0,s2
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	710080e7          	jalr	1808(ra) # 80000d2e <memmove>
    return 0;
    80002626:	8526                	mv	a0,s1
    80002628:	bff9                	j	80002606 <either_copyout+0x32>

000000008000262a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000262a:	7179                	addi	sp,sp,-48
    8000262c:	f406                	sd	ra,40(sp)
    8000262e:	f022                	sd	s0,32(sp)
    80002630:	ec26                	sd	s1,24(sp)
    80002632:	e84a                	sd	s2,16(sp)
    80002634:	e44e                	sd	s3,8(sp)
    80002636:	e052                	sd	s4,0(sp)
    80002638:	1800                	addi	s0,sp,48
    8000263a:	892a                	mv	s2,a0
    8000263c:	84ae                	mv	s1,a1
    8000263e:	89b2                	mv	s3,a2
    80002640:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	3f4080e7          	jalr	1012(ra) # 80001a36 <myproc>
  if (user_src)
    8000264a:	c08d                	beqz	s1,8000266c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000264c:	86d2                	mv	a3,s4
    8000264e:	864e                	mv	a2,s3
    80002650:	85ca                	mv	a1,s2
    80002652:	6d28                	ld	a0,88(a0)
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	0a0080e7          	jalr	160(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000265c:	70a2                	ld	ra,40(sp)
    8000265e:	7402                	ld	s0,32(sp)
    80002660:	64e2                	ld	s1,24(sp)
    80002662:	6942                	ld	s2,16(sp)
    80002664:	69a2                	ld	s3,8(sp)
    80002666:	6a02                	ld	s4,0(sp)
    80002668:	6145                	addi	sp,sp,48
    8000266a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000266c:	000a061b          	sext.w	a2,s4
    80002670:	85ce                	mv	a1,s3
    80002672:	854a                	mv	a0,s2
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	6ba080e7          	jalr	1722(ra) # 80000d2e <memmove>
    return 0;
    8000267c:	8526                	mv	a0,s1
    8000267e:	bff9                	j	8000265c <either_copyin+0x32>

0000000080002680 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002680:	715d                	addi	sp,sp,-80
    80002682:	e486                	sd	ra,72(sp)
    80002684:	e0a2                	sd	s0,64(sp)
    80002686:	fc26                	sd	s1,56(sp)
    80002688:	f84a                	sd	s2,48(sp)
    8000268a:	f44e                	sd	s3,40(sp)
    8000268c:	f052                	sd	s4,32(sp)
    8000268e:	ec56                	sd	s5,24(sp)
    80002690:	e85a                	sd	s6,16(sp)
    80002692:	e45e                	sd	s7,8(sp)
    80002694:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002696:	00006517          	auipc	a0,0x6
    8000269a:	a3250513          	addi	a0,a0,-1486 # 800080c8 <digits+0x88>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	eea080e7          	jalr	-278(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026a6:	0000f497          	auipc	s1,0xf
    800026aa:	29a48493          	addi	s1,s1,666 # 80011940 <proc+0x160>
    800026ae:	00019997          	auipc	s3,0x19
    800026b2:	a9298993          	addi	s3,s3,-1390 # 8001b140 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026b8:	00006a17          	auipc	s4,0x6
    800026bc:	bc8a0a13          	addi	s4,s4,-1080 # 80008280 <digits+0x240>
#ifdef rr
    printf("%d %s %s", p->pid, state, p->name);
    800026c0:	00006a97          	auipc	s5,0x6
    800026c4:	bc8a8a93          	addi	s5,s5,-1080 # 80008288 <digits+0x248>
    printf("\n");
    800026c8:	00006917          	auipc	s2,0x6
    800026cc:	a0090913          	addi	s2,s2,-1536 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d0:	00006b97          	auipc	s7,0x6
    800026d4:	bf8b8b93          	addi	s7,s7,-1032 # 800082c8 <states.0>
    800026d8:	a035                	j	80002704 <procdump+0x84>
    printf("%d %s %s", p->pid, state, p->name);
    800026da:	ed06a583          	lw	a1,-304(a3)
    800026de:	8556                	mv	a0,s5
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	ea8080e7          	jalr	-344(ra) # 80000588 <printf>
    printf("\n");
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	e9e080e7          	jalr	-354(ra) # 80000588 <printf>
#endif
#ifdef mlfq
    // int wtime = ticks - p->init_time - p->total_run_time;
    printf("%d %d %s %d %d %d %d %d %d\n", p->pid, p->mlfq_priority, state, p->total_run_time, p->runs_till_now, p->queue_run_time[0], p->queue_run_time[1], p->queue_run_time[2], p->queue_run_time[3]);
#endif
    printf("\n");
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e94080e7          	jalr	-364(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026fc:	26048493          	addi	s1,s1,608
    80002700:	03348163          	beq	s1,s3,80002722 <procdump+0xa2>
    if (p->state == UNUSED)
    80002704:	86a6                	mv	a3,s1
    80002706:	eb84a783          	lw	a5,-328(s1)
    8000270a:	dbed                	beqz	a5,800026fc <procdump+0x7c>
      state = "???";
    8000270c:	8652                	mv	a2,s4
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000270e:	fcfb66e3          	bltu	s6,a5,800026da <procdump+0x5a>
    80002712:	1782                	slli	a5,a5,0x20
    80002714:	9381                	srli	a5,a5,0x20
    80002716:	078e                	slli	a5,a5,0x3
    80002718:	97de                	add	a5,a5,s7
    8000271a:	6390                	ld	a2,0(a5)
    8000271c:	fe5d                	bnez	a2,800026da <procdump+0x5a>
      state = "???";
    8000271e:	8652                	mv	a2,s4
    80002720:	bf6d                	j	800026da <procdump+0x5a>
  }
}
    80002722:	60a6                	ld	ra,72(sp)
    80002724:	6406                	ld	s0,64(sp)
    80002726:	74e2                	ld	s1,56(sp)
    80002728:	7942                	ld	s2,48(sp)
    8000272a:	79a2                	ld	s3,40(sp)
    8000272c:	7a02                	ld	s4,32(sp)
    8000272e:	6ae2                	ld	s5,24(sp)
    80002730:	6b42                	ld	s6,16(sp)
    80002732:	6ba2                	ld	s7,8(sp)
    80002734:	6161                	addi	sp,sp,80
    80002736:	8082                	ret

0000000080002738 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002738:	711d                	addi	sp,sp,-96
    8000273a:	ec86                	sd	ra,88(sp)
    8000273c:	e8a2                	sd	s0,80(sp)
    8000273e:	e4a6                	sd	s1,72(sp)
    80002740:	e0ca                	sd	s2,64(sp)
    80002742:	fc4e                	sd	s3,56(sp)
    80002744:	f852                	sd	s4,48(sp)
    80002746:	f456                	sd	s5,40(sp)
    80002748:	f05a                	sd	s6,32(sp)
    8000274a:	ec5e                	sd	s7,24(sp)
    8000274c:	e862                	sd	s8,16(sp)
    8000274e:	e466                	sd	s9,8(sp)
    80002750:	e06a                	sd	s10,0(sp)
    80002752:	1080                	addi	s0,sp,96
    80002754:	8b2a                	mv	s6,a0
    80002756:	8bae                	mv	s7,a1
    80002758:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	2dc080e7          	jalr	732(ra) # 80001a36 <myproc>
    80002762:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002764:	0000e517          	auipc	a0,0xe
    80002768:	40450513          	addi	a0,a0,1028 # 80010b68 <wait_lock>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	46a080e7          	jalr	1130(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002774:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002776:	4a15                	li	s4,5
        havekids = 1;
    80002778:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000277a:	00019997          	auipc	s3,0x19
    8000277e:	86698993          	addi	s3,s3,-1946 # 8001afe0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002782:	0000ed17          	auipc	s10,0xe
    80002786:	3e6d0d13          	addi	s10,s10,998 # 80010b68 <wait_lock>
    havekids = 0;
    8000278a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000278c:	0000f497          	auipc	s1,0xf
    80002790:	05448493          	addi	s1,s1,84 # 800117e0 <proc>
    80002794:	a059                	j	8000281a <waitx+0xe2>
          pid = np->pid;
    80002796:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000279a:	1704a703          	lw	a4,368(s1)
    8000279e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800027a2:	1744a783          	lw	a5,372(s1)
    800027a6:	9f3d                	addw	a4,a4,a5
    800027a8:	1784a783          	lw	a5,376(s1)
    800027ac:	9f99                	subw	a5,a5,a4
    800027ae:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027b2:	000b0e63          	beqz	s6,800027ce <waitx+0x96>
    800027b6:	4691                	li	a3,4
    800027b8:	02c48613          	addi	a2,s1,44
    800027bc:	85da                	mv	a1,s6
    800027be:	05893503          	ld	a0,88(s2)
    800027c2:	fffff097          	auipc	ra,0xfffff
    800027c6:	ea6080e7          	jalr	-346(ra) # 80001668 <copyout>
    800027ca:	02054563          	bltz	a0,800027f4 <waitx+0xbc>
          freeproc(np);
    800027ce:	8526                	mv	a0,s1
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	478080e7          	jalr	1144(ra) # 80001c48 <freeproc>
          release(&np->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4b0080e7          	jalr	1200(ra) # 80000c8a <release>
          release(&wait_lock);
    800027e2:	0000e517          	auipc	a0,0xe
    800027e6:	38650513          	addi	a0,a0,902 # 80010b68 <wait_lock>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	4a0080e7          	jalr	1184(ra) # 80000c8a <release>
          return pid;
    800027f2:	a09d                	j	80002858 <waitx+0x120>
            release(&np->lock);
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	494080e7          	jalr	1172(ra) # 80000c8a <release>
            release(&wait_lock);
    800027fe:	0000e517          	auipc	a0,0xe
    80002802:	36a50513          	addi	a0,a0,874 # 80010b68 <wait_lock>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
            return -1;
    8000280e:	59fd                	li	s3,-1
    80002810:	a0a1                	j	80002858 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002812:	26048493          	addi	s1,s1,608
    80002816:	03348463          	beq	s1,s3,8000283e <waitx+0x106>
      if (np->parent == p)
    8000281a:	7c9c                	ld	a5,56(s1)
    8000281c:	ff279be3          	bne	a5,s2,80002812 <waitx+0xda>
        acquire(&np->lock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	3b4080e7          	jalr	948(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    8000282a:	4c9c                	lw	a5,24(s1)
    8000282c:	f74785e3          	beq	a5,s4,80002796 <waitx+0x5e>
        release(&np->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	458080e7          	jalr	1112(ra) # 80000c8a <release>
        havekids = 1;
    8000283a:	8756                	mv	a4,s5
    8000283c:	bfd9                	j	80002812 <waitx+0xda>
    if (!havekids || p->killed)
    8000283e:	c701                	beqz	a4,80002846 <waitx+0x10e>
    80002840:	02892783          	lw	a5,40(s2)
    80002844:	cb8d                	beqz	a5,80002876 <waitx+0x13e>
      release(&wait_lock);
    80002846:	0000e517          	auipc	a0,0xe
    8000284a:	32250513          	addi	a0,a0,802 # 80010b68 <wait_lock>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	43c080e7          	jalr	1084(ra) # 80000c8a <release>
      return -1;
    80002856:	59fd                	li	s3,-1
  }
}
    80002858:	854e                	mv	a0,s3
    8000285a:	60e6                	ld	ra,88(sp)
    8000285c:	6446                	ld	s0,80(sp)
    8000285e:	64a6                	ld	s1,72(sp)
    80002860:	6906                	ld	s2,64(sp)
    80002862:	79e2                	ld	s3,56(sp)
    80002864:	7a42                	ld	s4,48(sp)
    80002866:	7aa2                	ld	s5,40(sp)
    80002868:	7b02                	ld	s6,32(sp)
    8000286a:	6be2                	ld	s7,24(sp)
    8000286c:	6c42                	ld	s8,16(sp)
    8000286e:	6ca2                	ld	s9,8(sp)
    80002870:	6d02                	ld	s10,0(sp)
    80002872:	6125                	addi	sp,sp,96
    80002874:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002876:	85ea                	mv	a1,s10
    80002878:	854a                	mv	a0,s2
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	946080e7          	jalr	-1722(ra) # 800021c0 <sleep>
    havekids = 0;
    80002882:	b721                	j	8000278a <waitx+0x52>

0000000080002884 <update_time>:


void update_time()
{
    80002884:	7139                	addi	sp,sp,-64
    80002886:	fc06                	sd	ra,56(sp)
    80002888:	f822                	sd	s0,48(sp)
    8000288a:	f426                	sd	s1,40(sp)
    8000288c:	f04a                	sd	s2,32(sp)
    8000288e:	ec4e                	sd	s3,24(sp)
    80002890:	e852                	sd	s4,16(sp)
    80002892:	e456                	sd	s5,8(sp)
    80002894:	0080                	addi	s0,sp,64
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002896:	0000f497          	auipc	s1,0xf
    8000289a:	f4a48493          	addi	s1,s1,-182 # 800117e0 <proc>
    acquire(&p->lock);
#ifdef mlfq
    if (p->queued)
      p->queue_run_time[p->mlfq_priority]++;
#endif
    if (p->state == RUNNING)
    8000289e:	4991                	li	s3,4
#ifdef mlfq
      p->quantums_left--;
      p->queue_run_time[p->mlfq_priority]++;
#endif
    }
    else if (p->state == SLEEPING)
    800028a0:	4a09                	li	s4,2
      p->sleep_time++;
    else if (p->state == RUNNABLE)
    800028a2:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800028a4:	00018917          	auipc	s2,0x18
    800028a8:	73c90913          	addi	s2,s2,1852 # 8001afe0 <tickslock>
    800028ac:	a025                	j	800028d4 <update_time+0x50>
      p->run_time++;
    800028ae:	2004b783          	ld	a5,512(s1)
    800028b2:	0785                	addi	a5,a5,1
    800028b4:	20f4b023          	sd	a5,512(s1)
      p->total_run_time++;
    800028b8:	2084b783          	ld	a5,520(s1)
    800028bc:	0785                	addi	a5,a5,1
    800028be:	20f4b423          	sd	a5,520(s1)
        p->wait_time = 0;
        p->queue_in_time = ticks;
      }
#endif
    }
    release(&p->lock);
    800028c2:	8526                	mv	a0,s1
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	3c6080e7          	jalr	966(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028cc:	26048493          	addi	s1,s1,608
    800028d0:	03248a63          	beq	s1,s2,80002904 <update_time+0x80>
    acquire(&p->lock);
    800028d4:	8526                	mv	a0,s1
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800028de:	4c9c                	lw	a5,24(s1)
    800028e0:	fd3787e3          	beq	a5,s3,800028ae <update_time+0x2a>
    else if (p->state == SLEEPING)
    800028e4:	01478a63          	beq	a5,s4,800028f8 <update_time+0x74>
    else if (p->state == RUNNABLE)
    800028e8:	fd579de3          	bne	a5,s5,800028c2 <update_time+0x3e>
      p->wait_time++;
    800028ec:	1a44a783          	lw	a5,420(s1)
    800028f0:	2785                	addiw	a5,a5,1
    800028f2:	1af4a223          	sw	a5,420(s1)
    800028f6:	b7f1                	j	800028c2 <update_time+0x3e>
      p->sleep_time++;
    800028f8:	2104b783          	ld	a5,528(s1)
    800028fc:	0785                	addi	a5,a5,1
    800028fe:	20f4b823          	sd	a5,528(s1)
    80002902:	b7c1                	j	800028c2 <update_time+0x3e>
  }
}
    80002904:	70e2                	ld	ra,56(sp)
    80002906:	7442                	ld	s0,48(sp)
    80002908:	74a2                	ld	s1,40(sp)
    8000290a:	7902                	ld	s2,32(sp)
    8000290c:	69e2                	ld	s3,24(sp)
    8000290e:	6a42                	ld	s4,16(sp)
    80002910:	6aa2                	ld	s5,8(sp)
    80002912:	6121                	addi	sp,sp,64
    80002914:	8082                	ret

0000000080002916 <swtch>:
    80002916:	00153023          	sd	ra,0(a0)
    8000291a:	00253423          	sd	sp,8(a0)
    8000291e:	e900                	sd	s0,16(a0)
    80002920:	ed04                	sd	s1,24(a0)
    80002922:	03253023          	sd	s2,32(a0)
    80002926:	03353423          	sd	s3,40(a0)
    8000292a:	03453823          	sd	s4,48(a0)
    8000292e:	03553c23          	sd	s5,56(a0)
    80002932:	05653023          	sd	s6,64(a0)
    80002936:	05753423          	sd	s7,72(a0)
    8000293a:	05853823          	sd	s8,80(a0)
    8000293e:	05953c23          	sd	s9,88(a0)
    80002942:	07a53023          	sd	s10,96(a0)
    80002946:	07b53423          	sd	s11,104(a0)
    8000294a:	0005b083          	ld	ra,0(a1)
    8000294e:	0085b103          	ld	sp,8(a1)
    80002952:	6980                	ld	s0,16(a1)
    80002954:	6d84                	ld	s1,24(a1)
    80002956:	0205b903          	ld	s2,32(a1)
    8000295a:	0285b983          	ld	s3,40(a1)
    8000295e:	0305ba03          	ld	s4,48(a1)
    80002962:	0385ba83          	ld	s5,56(a1)
    80002966:	0405bb03          	ld	s6,64(a1)
    8000296a:	0485bb83          	ld	s7,72(a1)
    8000296e:	0505bc03          	ld	s8,80(a1)
    80002972:	0585bc83          	ld	s9,88(a1)
    80002976:	0605bd03          	ld	s10,96(a1)
    8000297a:	0685bd83          	ld	s11,104(a1)
    8000297e:	8082                	ret

0000000080002980 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002980:	1141                	addi	sp,sp,-16
    80002982:	e406                	sd	ra,8(sp)
    80002984:	e022                	sd	s0,0(sp)
    80002986:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002988:	00006597          	auipc	a1,0x6
    8000298c:	97058593          	addi	a1,a1,-1680 # 800082f8 <states.0+0x30>
    80002990:	00018517          	auipc	a0,0x18
    80002994:	65050513          	addi	a0,a0,1616 # 8001afe0 <tickslock>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	1ae080e7          	jalr	430(ra) # 80000b46 <initlock>
}
    800029a0:	60a2                	ld	ra,8(sp)
    800029a2:	6402                	ld	s0,0(sp)
    800029a4:	0141                	addi	sp,sp,16
    800029a6:	8082                	ret

00000000800029a8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029a8:	1141                	addi	sp,sp,-16
    800029aa:	e422                	sd	s0,8(sp)
    800029ac:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ae:	00003797          	auipc	a5,0x3
    800029b2:	6d278793          	addi	a5,a5,1746 # 80006080 <kernelvec>
    800029b6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029ba:	6422                	ld	s0,8(sp)
    800029bc:	0141                	addi	sp,sp,16
    800029be:	8082                	ret

00000000800029c0 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800029c0:	1141                	addi	sp,sp,-16
    800029c2:	e406                	sd	ra,8(sp)
    800029c4:	e022                	sd	s0,0(sp)
    800029c6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c8:	fffff097          	auipc	ra,0xfffff
    800029cc:	06e080e7          	jalr	110(ra) # 80001a36 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029da:	00004617          	auipc	a2,0x4
    800029de:	62660613          	addi	a2,a2,1574 # 80007000 <_trampoline>
    800029e2:	00004697          	auipc	a3,0x4
    800029e6:	61e68693          	addi	a3,a3,1566 # 80007000 <_trampoline>
    800029ea:	8e91                	sub	a3,a3,a2
    800029ec:	040007b7          	lui	a5,0x4000
    800029f0:	17fd                	addi	a5,a5,-1
    800029f2:	07b2                	slli	a5,a5,0xc
    800029f4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f6:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029fa:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029fc:	180026f3          	csrr	a3,satp
    80002a00:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a02:	7138                	ld	a4,96(a0)
    80002a04:	6534                	ld	a3,72(a0)
    80002a06:	6585                	lui	a1,0x1
    80002a08:	96ae                	add	a3,a3,a1
    80002a0a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a0c:	7138                	ld	a4,96(a0)
    80002a0e:	00000697          	auipc	a3,0x0
    80002a12:	13e68693          	addi	a3,a3,318 # 80002b4c <usertrap>
    80002a16:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a18:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a1a:	8692                	mv	a3,tp
    80002a1c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a22:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a26:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a2e:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a30:	6f18                	ld	a4,24(a4)
    80002a32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a36:	6d28                	ld	a0,88(a0)
    80002a38:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a3a:	00004717          	auipc	a4,0x4
    80002a3e:	66270713          	addi	a4,a4,1634 # 8000709c <userret>
    80002a42:	8f11                	sub	a4,a4,a2
    80002a44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a46:	577d                	li	a4,-1
    80002a48:	177e                	slli	a4,a4,0x3f
    80002a4a:	8d59                	or	a0,a0,a4
    80002a4c:	9782                	jalr	a5
}
    80002a4e:	60a2                	ld	ra,8(sp)
    80002a50:	6402                	ld	s0,0(sp)
    80002a52:	0141                	addi	sp,sp,16
    80002a54:	8082                	ret

0000000080002a56 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	e04a                	sd	s2,0(sp)
    80002a60:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a62:	00018917          	auipc	s2,0x18
    80002a66:	57e90913          	addi	s2,s2,1406 # 8001afe0 <tickslock>
    80002a6a:	854a                	mv	a0,s2
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	16a080e7          	jalr	362(ra) # 80000bd6 <acquire>
  ticks++;
    80002a74:	00006497          	auipc	s1,0x6
    80002a78:	e6c48493          	addi	s1,s1,-404 # 800088e0 <ticks>
    80002a7c:	409c                	lw	a5,0(s1)
    80002a7e:	2785                	addiw	a5,a5,1
    80002a80:	c09c                	sw	a5,0(s1)
  update_time();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	e02080e7          	jalr	-510(ra) # 80002884 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	798080e7          	jalr	1944(ra) # 80002224 <wakeup>
  release(&tickslock);
    80002a94:	854a                	mv	a0,s2
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	1f4080e7          	jalr	500(ra) # 80000c8a <release>
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6902                	ld	s2,0(sp)
    80002aa6:	6105                	addi	sp,sp,32
    80002aa8:	8082                	ret

0000000080002aaa <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002ab8:	00074d63          	bltz	a4,80002ad2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002abc:	57fd                	li	a5,-1
    80002abe:	17fe                	slli	a5,a5,0x3f
    80002ac0:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002ac2:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002ac4:	06f70363          	beq	a4,a5,80002b2a <devintr+0x80>
  }
    80002ac8:	60e2                	ld	ra,24(sp)
    80002aca:	6442                	ld	s0,16(sp)
    80002acc:	64a2                	ld	s1,8(sp)
    80002ace:	6105                	addi	sp,sp,32
    80002ad0:	8082                	ret
      (scause & 0xff) == 9)
    80002ad2:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002ad6:	46a5                	li	a3,9
    80002ad8:	fed792e3          	bne	a5,a3,80002abc <devintr+0x12>
    int irq = plic_claim();
    80002adc:	00003097          	auipc	ra,0x3
    80002ae0:	6ac080e7          	jalr	1708(ra) # 80006188 <plic_claim>
    80002ae4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ae6:	47a9                	li	a5,10
    80002ae8:	02f50763          	beq	a0,a5,80002b16 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002aec:	4785                	li	a5,1
    80002aee:	02f50963          	beq	a0,a5,80002b20 <devintr+0x76>
    return 1;
    80002af2:	4505                	li	a0,1
    else if (irq)
    80002af4:	d8f1                	beqz	s1,80002ac8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002af6:	85a6                	mv	a1,s1
    80002af8:	00006517          	auipc	a0,0x6
    80002afc:	80850513          	addi	a0,a0,-2040 # 80008300 <states.0+0x38>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a88080e7          	jalr	-1400(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b08:	8526                	mv	a0,s1
    80002b0a:	00003097          	auipc	ra,0x3
    80002b0e:	6a2080e7          	jalr	1698(ra) # 800061ac <plic_complete>
    return 1;
    80002b12:	4505                	li	a0,1
    80002b14:	bf55                	j	80002ac8 <devintr+0x1e>
      uartintr();
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	e84080e7          	jalr	-380(ra) # 8000099a <uartintr>
    80002b1e:	b7ed                	j	80002b08 <devintr+0x5e>
      virtio_disk_intr();
    80002b20:	00004097          	auipc	ra,0x4
    80002b24:	b58080e7          	jalr	-1192(ra) # 80006678 <virtio_disk_intr>
    80002b28:	b7c5                	j	80002b08 <devintr+0x5e>
    if (cpuid() == 0)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	ee0080e7          	jalr	-288(ra) # 80001a0a <cpuid>
    80002b32:	c901                	beqz	a0,80002b42 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b34:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b3a:	14479073          	csrw	sip,a5
    return 2;
    80002b3e:	4509                	li	a0,2
    80002b40:	b761                	j	80002ac8 <devintr+0x1e>
      clockintr();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	f14080e7          	jalr	-236(ra) # 80002a56 <clockintr>
    80002b4a:	b7ed                	j	80002b34 <devintr+0x8a>

0000000080002b4c <usertrap>:
{
    80002b4c:	1101                	addi	sp,sp,-32
    80002b4e:	ec06                	sd	ra,24(sp)
    80002b50:	e822                	sd	s0,16(sp)
    80002b52:	e426                	sd	s1,8(sp)
    80002b54:	e04a                	sd	s2,0(sp)
    80002b56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b58:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b5c:	1007f793          	andi	a5,a5,256
    80002b60:	e3b1                	bnez	a5,80002ba4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b62:	00003797          	auipc	a5,0x3
    80002b66:	51e78793          	addi	a5,a5,1310 # 80006080 <kernelvec>
    80002b6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	ec8080e7          	jalr	-312(ra) # 80001a36 <myproc>
    80002b76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b78:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7a:	14102773          	csrr	a4,sepc
    80002b7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b80:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b84:	47a1                	li	a5,8
    80002b86:	02f70763          	beq	a4,a5,80002bb4 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	f20080e7          	jalr	-224(ra) # 80002aaa <devintr>
    80002b92:	892a                	mv	s2,a0
    80002b94:	c92d                	beqz	a0,80002c06 <usertrap+0xba>
  if (killed(p))
    80002b96:	8526                	mv	a0,s1
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	8dc080e7          	jalr	-1828(ra) # 80002474 <killed>
    80002ba0:	c555                	beqz	a0,80002c4c <usertrap+0x100>
    80002ba2:	a045                	j	80002c42 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002ba4:	00005517          	auipc	a0,0x5
    80002ba8:	77c50513          	addi	a0,a0,1916 # 80008320 <states.0+0x58>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	992080e7          	jalr	-1646(ra) # 8000053e <panic>
    if (killed(p))
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	8c0080e7          	jalr	-1856(ra) # 80002474 <killed>
    80002bbc:	ed1d                	bnez	a0,80002bfa <usertrap+0xae>
    p->trapframe->epc += 4;
    80002bbe:	70b8                	ld	a4,96(s1)
    80002bc0:	6f1c                	ld	a5,24(a4)
    80002bc2:	0791                	addi	a5,a5,4
    80002bc4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10079073          	csrw	sstatus,a5
    syscall();
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	322080e7          	jalr	802(ra) # 80002ef4 <syscall>
  if (killed(p))
    80002bda:	8526                	mv	a0,s1
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	898080e7          	jalr	-1896(ra) # 80002474 <killed>
    80002be4:	ed31                	bnez	a0,80002c40 <usertrap+0xf4>
  usertrapret();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	dda080e7          	jalr	-550(ra) # 800029c0 <usertrapret>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
      exit(-1);
    80002bfa:	557d                	li	a0,-1
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	6f8080e7          	jalr	1784(ra) # 800022f4 <exit>
    80002c04:	bf6d                	j	80002bbe <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c06:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c0a:	5890                	lw	a2,48(s1)
    80002c0c:	00005517          	auipc	a0,0x5
    80002c10:	73450513          	addi	a0,a0,1844 # 80008340 <states.0+0x78>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	974080e7          	jalr	-1676(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c20:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c24:	00005517          	auipc	a0,0x5
    80002c28:	74c50513          	addi	a0,a0,1868 # 80008370 <states.0+0xa8>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95c080e7          	jalr	-1700(ra) # 80000588 <printf>
    setkilled(p);
    80002c34:	8526                	mv	a0,s1
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	812080e7          	jalr	-2030(ra) # 80002448 <setkilled>
    80002c3e:	bf71                	j	80002bda <usertrap+0x8e>
  if (killed(p))
    80002c40:	4901                	li	s2,0
    exit(-1);
    80002c42:	557d                	li	a0,-1
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	6b0080e7          	jalr	1712(ra) # 800022f4 <exit>
  if (which_dev == 2)
    80002c4c:	4789                	li	a5,2
    80002c4e:	f8f91ce3          	bne	s2,a5,80002be6 <usertrap+0x9a>
      if(p->ticks){
    80002c52:	2184a703          	lw	a4,536(s1)
    80002c56:	cf19                	beqz	a4,80002c74 <usertrap+0x128>
      p->cur_ticks ++;
    80002c58:	21c4a783          	lw	a5,540(s1)
    80002c5c:	2785                	addiw	a5,a5,1
    80002c5e:	0007869b          	sext.w	a3,a5
    80002c62:	20f4ae23          	sw	a5,540(s1)
      if(p->alarm_on==0 && p->ticks >0 && p->cur_ticks>=p->ticks){
    80002c66:	2284a783          	lw	a5,552(s1)
    80002c6a:	e789                	bnez	a5,80002c74 <usertrap+0x128>
    80002c6c:	00e05463          	blez	a4,80002c74 <usertrap+0x128>
    80002c70:	00e6d763          	bge	a3,a4,80002c7e <usertrap+0x132>
    yield();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	510080e7          	jalr	1296(ra) # 80002184 <yield>
    80002c7c:	b7ad                	j	80002be6 <usertrap+0x9a>
        p->cur_ticks=0;
    80002c7e:	2004ae23          	sw	zero,540(s1)
        p->alarm_on=1;
    80002c82:	4785                	li	a5,1
    80002c84:	22f4a423          	sw	a5,552(s1)
        p->alarm_tf=kalloc();
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	e5e080e7          	jalr	-418(ra) # 80000ae6 <kalloc>
    80002c90:	22a4b023          	sd	a0,544(s1)
      memmove(p->alarm_tf, p->trapframe, PGSIZE);
    80002c94:	6605                	lui	a2,0x1
    80002c96:	70ac                	ld	a1,96(s1)
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	096080e7          	jalr	150(ra) # 80000d2e <memmove>
        p->trapframe->epc = p->handler;
    80002ca0:	70bc                	ld	a5,96(s1)
    80002ca2:	2504b703          	ld	a4,592(s1)
    80002ca6:	ef98                	sd	a4,24(a5)
    80002ca8:	b7f1                	j	80002c74 <usertrap+0x128>

0000000080002caa <kerneltrap>:
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	e84a                	sd	s2,16(sp)
    80002cb4:	e44e                	sd	s3,8(sp)
    80002cb6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cbc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cc0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002cc4:	1004f793          	andi	a5,s1,256
    80002cc8:	cb85                	beqz	a5,80002cf8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cce:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002cd0:	ef85                	bnez	a5,80002d08 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	dd8080e7          	jalr	-552(ra) # 80002aaa <devintr>
    80002cda:	cd1d                	beqz	a0,80002d18 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cdc:	4789                	li	a5,2
    80002cde:	06f50a63          	beq	a0,a5,80002d52 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ce2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce6:	10049073          	csrw	sstatus,s1
}
    80002cea:	70a2                	ld	ra,40(sp)
    80002cec:	7402                	ld	s0,32(sp)
    80002cee:	64e2                	ld	s1,24(sp)
    80002cf0:	6942                	ld	s2,16(sp)
    80002cf2:	69a2                	ld	s3,8(sp)
    80002cf4:	6145                	addi	sp,sp,48
    80002cf6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	69850513          	addi	a0,a0,1688 # 80008390 <states.0+0xc8>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	83e080e7          	jalr	-1986(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d08:	00005517          	auipc	a0,0x5
    80002d0c:	6b050513          	addi	a0,a0,1712 # 800083b8 <states.0+0xf0>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d18:	85ce                	mv	a1,s3
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	6be50513          	addi	a0,a0,1726 # 800083d8 <states.0+0x110>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	866080e7          	jalr	-1946(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d2e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	6b650513          	addi	a0,a0,1718 # 800083e8 <states.0+0x120>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	84e080e7          	jalr	-1970(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d42:	00005517          	auipc	a0,0x5
    80002d46:	6be50513          	addi	a0,a0,1726 # 80008400 <states.0+0x138>
    80002d4a:	ffffd097          	auipc	ra,0xffffd
    80002d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	ce4080e7          	jalr	-796(ra) # 80001a36 <myproc>
    80002d5a:	d541                	beqz	a0,80002ce2 <kerneltrap+0x38>
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	cda080e7          	jalr	-806(ra) # 80001a36 <myproc>
    80002d64:	4d18                	lw	a4,24(a0)
    80002d66:	4791                	li	a5,4
    80002d68:	f6f71de3          	bne	a4,a5,80002ce2 <kerneltrap+0x38>
    yield();
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	418080e7          	jalr	1048(ra) # 80002184 <yield>
    80002d74:	b7bd                	j	80002ce2 <kerneltrap+0x38>

0000000080002d76 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	e426                	sd	s1,8(sp)
    80002d7e:	1000                	addi	s0,sp,32
    80002d80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	cb4080e7          	jalr	-844(ra) # 80001a36 <myproc>
  switch (n) {
    80002d8a:	4795                	li	a5,5
    80002d8c:	0497e163          	bltu	a5,s1,80002dce <argraw+0x58>
    80002d90:	048a                	slli	s1,s1,0x2
    80002d92:	00005717          	auipc	a4,0x5
    80002d96:	6a670713          	addi	a4,a4,1702 # 80008438 <states.0+0x170>
    80002d9a:	94ba                	add	s1,s1,a4
    80002d9c:	409c                	lw	a5,0(s1)
    80002d9e:	97ba                	add	a5,a5,a4
    80002da0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002da2:	713c                	ld	a5,96(a0)
    80002da4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	64a2                	ld	s1,8(sp)
    80002dac:	6105                	addi	sp,sp,32
    80002dae:	8082                	ret
    return p->trapframe->a1;
    80002db0:	713c                	ld	a5,96(a0)
    80002db2:	7fa8                	ld	a0,120(a5)
    80002db4:	bfcd                	j	80002da6 <argraw+0x30>
    return p->trapframe->a2;
    80002db6:	713c                	ld	a5,96(a0)
    80002db8:	63c8                	ld	a0,128(a5)
    80002dba:	b7f5                	j	80002da6 <argraw+0x30>
    return p->trapframe->a3;
    80002dbc:	713c                	ld	a5,96(a0)
    80002dbe:	67c8                	ld	a0,136(a5)
    80002dc0:	b7dd                	j	80002da6 <argraw+0x30>
    return p->trapframe->a4;
    80002dc2:	713c                	ld	a5,96(a0)
    80002dc4:	6bc8                	ld	a0,144(a5)
    80002dc6:	b7c5                	j	80002da6 <argraw+0x30>
    return p->trapframe->a5;
    80002dc8:	713c                	ld	a5,96(a0)
    80002dca:	6fc8                	ld	a0,152(a5)
    80002dcc:	bfe9                	j	80002da6 <argraw+0x30>
  panic("argraw");
    80002dce:	00005517          	auipc	a0,0x5
    80002dd2:	64250513          	addi	a0,a0,1602 # 80008410 <states.0+0x148>
    80002dd6:	ffffd097          	auipc	ra,0xffffd
    80002dda:	768080e7          	jalr	1896(ra) # 8000053e <panic>

0000000080002dde <fetchaddr>:
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	e426                	sd	s1,8(sp)
    80002de6:	e04a                	sd	s2,0(sp)
    80002de8:	1000                	addi	s0,sp,32
    80002dea:	84aa                	mv	s1,a0
    80002dec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	c48080e7          	jalr	-952(ra) # 80001a36 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002df6:	693c                	ld	a5,80(a0)
    80002df8:	02f4f863          	bgeu	s1,a5,80002e28 <fetchaddr+0x4a>
    80002dfc:	00848713          	addi	a4,s1,8
    80002e00:	02e7e663          	bltu	a5,a4,80002e2c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e04:	46a1                	li	a3,8
    80002e06:	8626                	mv	a2,s1
    80002e08:	85ca                	mv	a1,s2
    80002e0a:	6d28                	ld	a0,88(a0)
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	8e8080e7          	jalr	-1816(ra) # 800016f4 <copyin>
    80002e14:	00a03533          	snez	a0,a0
    80002e18:	40a00533          	neg	a0,a0
}
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6902                	ld	s2,0(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret
    return -1;
    80002e28:	557d                	li	a0,-1
    80002e2a:	bfcd                	j	80002e1c <fetchaddr+0x3e>
    80002e2c:	557d                	li	a0,-1
    80002e2e:	b7fd                	j	80002e1c <fetchaddr+0x3e>

0000000080002e30 <fetchstr>:
{
    80002e30:	7179                	addi	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	e84a                	sd	s2,16(sp)
    80002e3a:	e44e                	sd	s3,8(sp)
    80002e3c:	1800                	addi	s0,sp,48
    80002e3e:	892a                	mv	s2,a0
    80002e40:	84ae                	mv	s1,a1
    80002e42:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	bf2080e7          	jalr	-1038(ra) # 80001a36 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e4c:	86ce                	mv	a3,s3
    80002e4e:	864a                	mv	a2,s2
    80002e50:	85a6                	mv	a1,s1
    80002e52:	6d28                	ld	a0,88(a0)
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	92e080e7          	jalr	-1746(ra) # 80001782 <copyinstr>
    80002e5c:	00054e63          	bltz	a0,80002e78 <fetchstr+0x48>
  return strlen(buf);
    80002e60:	8526                	mv	a0,s1
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	fec080e7          	jalr	-20(ra) # 80000e4e <strlen>
}
    80002e6a:	70a2                	ld	ra,40(sp)
    80002e6c:	7402                	ld	s0,32(sp)
    80002e6e:	64e2                	ld	s1,24(sp)
    80002e70:	6942                	ld	s2,16(sp)
    80002e72:	69a2                	ld	s3,8(sp)
    80002e74:	6145                	addi	sp,sp,48
    80002e76:	8082                	ret
    return -1;
    80002e78:	557d                	li	a0,-1
    80002e7a:	bfc5                	j	80002e6a <fetchstr+0x3a>

0000000080002e7c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e7c:	1101                	addi	sp,sp,-32
    80002e7e:	ec06                	sd	ra,24(sp)
    80002e80:	e822                	sd	s0,16(sp)
    80002e82:	e426                	sd	s1,8(sp)
    80002e84:	1000                	addi	s0,sp,32
    80002e86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	eee080e7          	jalr	-274(ra) # 80002d76 <argraw>
    80002e90:	c088                	sw	a0,0(s1)
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	64a2                	ld	s1,8(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	e426                	sd	s1,8(sp)
    80002ea4:	1000                	addi	s0,sp,32
    80002ea6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	ece080e7          	jalr	-306(ra) # 80002d76 <argraw>
    80002eb0:	e088                	sd	a0,0(s1)
}
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret

0000000080002ebc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ebc:	7179                	addi	sp,sp,-48
    80002ebe:	f406                	sd	ra,40(sp)
    80002ec0:	f022                	sd	s0,32(sp)
    80002ec2:	ec26                	sd	s1,24(sp)
    80002ec4:	e84a                	sd	s2,16(sp)
    80002ec6:	1800                	addi	s0,sp,48
    80002ec8:	84ae                	mv	s1,a1
    80002eca:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ecc:	fd840593          	addi	a1,s0,-40
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	fcc080e7          	jalr	-52(ra) # 80002e9c <argaddr>
  return fetchstr(addr, buf, max);
    80002ed8:	864a                	mv	a2,s2
    80002eda:	85a6                	mv	a1,s1
    80002edc:	fd843503          	ld	a0,-40(s0)
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	f50080e7          	jalr	-176(ra) # 80002e30 <fetchstr>
}
    80002ee8:	70a2                	ld	ra,40(sp)
    80002eea:	7402                	ld	s0,32(sp)
    80002eec:	64e2                	ld	s1,24(sp)
    80002eee:	6942                	ld	s2,16(sp)
    80002ef0:	6145                	addi	sp,sp,48
    80002ef2:	8082                	ret

0000000080002ef4 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	e426                	sd	s1,8(sp)
    80002efc:	e04a                	sd	s2,0(sp)
    80002efe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	b36080e7          	jalr	-1226(ra) # 80001a36 <myproc>
    80002f08:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f0a:	06053903          	ld	s2,96(a0)
    80002f0e:	0a893783          	ld	a5,168(s2)
    80002f12:	0007869b          	sext.w	a3,a5
   if (num==SYS_read){
    80002f16:	4715                	li	a4,5
    80002f18:	02e68663          	beq	a3,a4,80002f44 <syscall+0x50>
    readcount++; //my change
  }
  if (num==SYS_getreadcount){
    80002f1c:	475d                	li	a4,23
    80002f1e:	04e69663          	bne	a3,a4,80002f6a <syscall+0x76>
    p->readcallcount = readcount; //my change
    80002f22:	00006717          	auipc	a4,0x6
    80002f26:	9c272703          	lw	a4,-1598(a4) # 800088e4 <readcount>
    80002f2a:	c138                	sw	a4,64(a0)
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f2c:	37fd                	addiw	a5,a5,-1
    80002f2e:	4661                	li	a2,24
    80002f30:	00000717          	auipc	a4,0x0
    80002f34:	3ae70713          	addi	a4,a4,942 # 800032de <sys_getreadcount>
    80002f38:	04f66663          	bltu	a2,a5,80002f84 <syscall+0x90>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f3c:	9702                	jalr	a4
    80002f3e:	06a93823          	sd	a0,112(s2)
    80002f42:	a8b9                	j	80002fa0 <syscall+0xac>
    readcount++; //my change
    80002f44:	00006617          	auipc	a2,0x6
    80002f48:	9a060613          	addi	a2,a2,-1632 # 800088e4 <readcount>
    80002f4c:	4218                	lw	a4,0(a2)
    80002f4e:	2705                	addiw	a4,a4,1
    80002f50:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f52:	37fd                	addiw	a5,a5,-1
    80002f54:	4761                	li	a4,24
    80002f56:	02f76763          	bltu	a4,a5,80002f84 <syscall+0x90>
    80002f5a:	068e                	slli	a3,a3,0x3
    80002f5c:	00005797          	auipc	a5,0x5
    80002f60:	4f478793          	addi	a5,a5,1268 # 80008450 <syscalls>
    80002f64:	96be                	add	a3,a3,a5
    80002f66:	6298                	ld	a4,0(a3)
    80002f68:	bfd1                	j	80002f3c <syscall+0x48>
    80002f6a:	37fd                	addiw	a5,a5,-1
    80002f6c:	4761                	li	a4,24
    80002f6e:	00f76b63          	bltu	a4,a5,80002f84 <syscall+0x90>
    80002f72:	00369713          	slli	a4,a3,0x3
    80002f76:	00005797          	auipc	a5,0x5
    80002f7a:	4da78793          	addi	a5,a5,1242 # 80008450 <syscalls>
    80002f7e:	97ba                	add	a5,a5,a4
    80002f80:	6398                	ld	a4,0(a5)
    80002f82:	ff4d                	bnez	a4,80002f3c <syscall+0x48>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f84:	16048613          	addi	a2,s1,352
    80002f88:	588c                	lw	a1,48(s1)
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	48e50513          	addi	a0,a0,1166 # 80008418 <states.0+0x150>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f9a:	70bc                	ld	a5,96(s1)
    80002f9c:	577d                	li	a4,-1
    80002f9e:	fbb8                	sd	a4,112(a5)
  }
}
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	64a2                	ld	s1,8(sp)
    80002fa6:	6902                	ld	s2,0(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret

0000000080002fac <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002fb4:	fec40593          	addi	a1,s0,-20
    80002fb8:	4501                	li	a0,0
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	ec2080e7          	jalr	-318(ra) # 80002e7c <argint>
  exit(n);
    80002fc2:	fec42503          	lw	a0,-20(s0)
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	32e080e7          	jalr	814(ra) # 800022f4 <exit>
  return 0; // not reached
}
    80002fce:	4501                	li	a0,0
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	6105                	addi	sp,sp,32
    80002fd6:	8082                	ret

0000000080002fd8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fd8:	1141                	addi	sp,sp,-16
    80002fda:	e406                	sd	ra,8(sp)
    80002fdc:	e022                	sd	s0,0(sp)
    80002fde:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	a56080e7          	jalr	-1450(ra) # 80001a36 <myproc>
}
    80002fe8:	5908                	lw	a0,48(a0)
    80002fea:	60a2                	ld	ra,8(sp)
    80002fec:	6402                	ld	s0,0(sp)
    80002fee:	0141                	addi	sp,sp,16
    80002ff0:	8082                	ret

0000000080002ff2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ff2:	1141                	addi	sp,sp,-16
    80002ff4:	e406                	sd	ra,8(sp)
    80002ff6:	e022                	sd	s0,0(sp)
    80002ff8:	0800                	addi	s0,sp,16
  return fork();
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	ed4080e7          	jalr	-300(ra) # 80001ece <fork>
}
    80003002:	60a2                	ld	ra,8(sp)
    80003004:	6402                	ld	s0,0(sp)
    80003006:	0141                	addi	sp,sp,16
    80003008:	8082                	ret

000000008000300a <sys_wait>:

uint64
sys_wait(void)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003012:	fe840593          	addi	a1,s0,-24
    80003016:	4501                	li	a0,0
    80003018:	00000097          	auipc	ra,0x0
    8000301c:	e84080e7          	jalr	-380(ra) # 80002e9c <argaddr>
  return wait(p);
    80003020:	fe843503          	ld	a0,-24(s0)
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	482080e7          	jalr	1154(ra) # 800024a6 <wait>
}
    8000302c:	60e2                	ld	ra,24(sp)
    8000302e:	6442                	ld	s0,16(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret

0000000080003034 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003034:	7179                	addi	sp,sp,-48
    80003036:	f406                	sd	ra,40(sp)
    80003038:	f022                	sd	s0,32(sp)
    8000303a:	ec26                	sd	s1,24(sp)
    8000303c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000303e:	fdc40593          	addi	a1,s0,-36
    80003042:	4501                	li	a0,0
    80003044:	00000097          	auipc	ra,0x0
    80003048:	e38080e7          	jalr	-456(ra) # 80002e7c <argint>
  addr = myproc()->sz;
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	9ea080e7          	jalr	-1558(ra) # 80001a36 <myproc>
    80003054:	6924                	ld	s1,80(a0)
  if (growproc(n) < 0)
    80003056:	fdc42503          	lw	a0,-36(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	e18080e7          	jalr	-488(ra) # 80001e72 <growproc>
    80003062:	00054863          	bltz	a0,80003072 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003066:	8526                	mv	a0,s1
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6145                	addi	sp,sp,48
    80003070:	8082                	ret
    return -1;
    80003072:	54fd                	li	s1,-1
    80003074:	bfcd                	j	80003066 <sys_sbrk+0x32>

0000000080003076 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003076:	7139                	addi	sp,sp,-64
    80003078:	fc06                	sd	ra,56(sp)
    8000307a:	f822                	sd	s0,48(sp)
    8000307c:	f426                	sd	s1,40(sp)
    8000307e:	f04a                	sd	s2,32(sp)
    80003080:	ec4e                	sd	s3,24(sp)
    80003082:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003084:	fcc40593          	addi	a1,s0,-52
    80003088:	4501                	li	a0,0
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	df2080e7          	jalr	-526(ra) # 80002e7c <argint>
  acquire(&tickslock);
    80003092:	00018517          	auipc	a0,0x18
    80003096:	f4e50513          	addi	a0,a0,-178 # 8001afe0 <tickslock>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	b3c080e7          	jalr	-1220(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800030a2:	00006917          	auipc	s2,0x6
    800030a6:	83e92903          	lw	s2,-1986(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    800030aa:	fcc42783          	lw	a5,-52(s0)
    800030ae:	cf9d                	beqz	a5,800030ec <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030b0:	00018997          	auipc	s3,0x18
    800030b4:	f3098993          	addi	s3,s3,-208 # 8001afe0 <tickslock>
    800030b8:	00006497          	auipc	s1,0x6
    800030bc:	82848493          	addi	s1,s1,-2008 # 800088e0 <ticks>
    if (killed(myproc()))
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	976080e7          	jalr	-1674(ra) # 80001a36 <myproc>
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	3ac080e7          	jalr	940(ra) # 80002474 <killed>
    800030d0:	ed15                	bnez	a0,8000310c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800030d2:	85ce                	mv	a1,s3
    800030d4:	8526                	mv	a0,s1
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	0ea080e7          	jalr	234(ra) # 800021c0 <sleep>
  while (ticks - ticks0 < n)
    800030de:	409c                	lw	a5,0(s1)
    800030e0:	412787bb          	subw	a5,a5,s2
    800030e4:	fcc42703          	lw	a4,-52(s0)
    800030e8:	fce7ece3          	bltu	a5,a4,800030c0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800030ec:	00018517          	auipc	a0,0x18
    800030f0:	ef450513          	addi	a0,a0,-268 # 8001afe0 <tickslock>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	b96080e7          	jalr	-1130(ra) # 80000c8a <release>
  return 0;
    800030fc:	4501                	li	a0,0
}
    800030fe:	70e2                	ld	ra,56(sp)
    80003100:	7442                	ld	s0,48(sp)
    80003102:	74a2                	ld	s1,40(sp)
    80003104:	7902                	ld	s2,32(sp)
    80003106:	69e2                	ld	s3,24(sp)
    80003108:	6121                	addi	sp,sp,64
    8000310a:	8082                	ret
      release(&tickslock);
    8000310c:	00018517          	auipc	a0,0x18
    80003110:	ed450513          	addi	a0,a0,-300 # 8001afe0 <tickslock>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	b76080e7          	jalr	-1162(ra) # 80000c8a <release>
      return -1;
    8000311c:	557d                	li	a0,-1
    8000311e:	b7c5                	j	800030fe <sys_sleep+0x88>

0000000080003120 <sys_kill>:

uint64
sys_kill(void)
{
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003128:	fec40593          	addi	a1,s0,-20
    8000312c:	4501                	li	a0,0
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	d4e080e7          	jalr	-690(ra) # 80002e7c <argint>
  return kill(pid);
    80003136:	fec42503          	lw	a0,-20(s0)
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	29c080e7          	jalr	668(ra) # 800023d6 <kill>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	6105                	addi	sp,sp,32
    80003148:	8082                	ret

000000008000314a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000314a:	1101                	addi	sp,sp,-32
    8000314c:	ec06                	sd	ra,24(sp)
    8000314e:	e822                	sd	s0,16(sp)
    80003150:	e426                	sd	s1,8(sp)
    80003152:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003154:	00018517          	auipc	a0,0x18
    80003158:	e8c50513          	addi	a0,a0,-372 # 8001afe0 <tickslock>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	a7a080e7          	jalr	-1414(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003164:	00005497          	auipc	s1,0x5
    80003168:	77c4a483          	lw	s1,1916(s1) # 800088e0 <ticks>
  release(&tickslock);
    8000316c:	00018517          	auipc	a0,0x18
    80003170:	e7450513          	addi	a0,a0,-396 # 8001afe0 <tickslock>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b16080e7          	jalr	-1258(ra) # 80000c8a <release>
  return xticks;
}
    8000317c:	02049513          	slli	a0,s1,0x20
    80003180:	9101                	srli	a0,a0,0x20
    80003182:	60e2                	ld	ra,24(sp)
    80003184:	6442                	ld	s0,16(sp)
    80003186:	64a2                	ld	s1,8(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000318c:	7139                	addi	sp,sp,-64
    8000318e:	fc06                	sd	ra,56(sp)
    80003190:	f822                	sd	s0,48(sp)
    80003192:	f426                	sd	s1,40(sp)
    80003194:	f04a                	sd	s2,32(sp)
    80003196:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003198:	fd840593          	addi	a1,s0,-40
    8000319c:	4501                	li	a0,0
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	cfe080e7          	jalr	-770(ra) # 80002e9c <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800031a6:	fd040593          	addi	a1,s0,-48
    800031aa:	4505                	li	a0,1
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	cf0080e7          	jalr	-784(ra) # 80002e9c <argaddr>
  argaddr(2, &addr2);
    800031b4:	fc840593          	addi	a1,s0,-56
    800031b8:	4509                	li	a0,2
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	ce2080e7          	jalr	-798(ra) # 80002e9c <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800031c2:	fc040613          	addi	a2,s0,-64
    800031c6:	fc440593          	addi	a1,s0,-60
    800031ca:	fd843503          	ld	a0,-40(s0)
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	56a080e7          	jalr	1386(ra) # 80002738 <waitx>
    800031d6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	85e080e7          	jalr	-1954(ra) # 80001a36 <myproc>
    800031e0:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800031e2:	4691                	li	a3,4
    800031e4:	fc440613          	addi	a2,s0,-60
    800031e8:	fd043583          	ld	a1,-48(s0)
    800031ec:	6d28                	ld	a0,88(a0)
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	47a080e7          	jalr	1146(ra) # 80001668 <copyout>
    return -1;
    800031f6:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800031f8:	00054f63          	bltz	a0,80003216 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800031fc:	4691                	li	a3,4
    800031fe:	fc040613          	addi	a2,s0,-64
    80003202:	fc843583          	ld	a1,-56(s0)
    80003206:	6ca8                	ld	a0,88(s1)
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	460080e7          	jalr	1120(ra) # 80001668 <copyout>
    80003210:	00054a63          	bltz	a0,80003224 <sys_waitx+0x98>
    return -1;
  return ret;
    80003214:	87ca                	mv	a5,s2
}
    80003216:	853e                	mv	a0,a5
    80003218:	70e2                	ld	ra,56(sp)
    8000321a:	7442                	ld	s0,48(sp)
    8000321c:	74a2                	ld	s1,40(sp)
    8000321e:	7902                	ld	s2,32(sp)
    80003220:	6121                	addi	sp,sp,64
    80003222:	8082                	ret
    return -1;
    80003224:	57fd                	li	a5,-1
    80003226:	bfc5                	j	80003216 <sys_waitx+0x8a>

0000000080003228 <sys_sigalarm>:


uint64 sys_sigalarm(void)
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    80003230:	fe440593          	addi	a1,s0,-28
    80003234:	4501                	li	a0,0
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	c46080e7          	jalr	-954(ra) # 80002e7c <argint>
  argaddr(1, &addr);
    8000323e:	fe840593          	addi	a1,s0,-24
    80003242:	4505                	li	a0,1
    80003244:	00000097          	auipc	ra,0x0
    80003248:	c58080e7          	jalr	-936(ra) # 80002e9c <argaddr>

  myproc()->ticks = ticks;
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	7ea080e7          	jalr	2026(ra) # 80001a36 <myproc>
    80003254:	fe442783          	lw	a5,-28(s0)
    80003258:	20f52c23          	sw	a5,536(a0)
  myproc()->alarm_on=0;
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	7da080e7          	jalr	2010(ra) # 80001a36 <myproc>
    80003264:	22052423          	sw	zero,552(a0)
  myproc()->cur_ticks=0;
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	7ce080e7          	jalr	1998(ra) # 80001a36 <myproc>
    80003270:	20052e23          	sw	zero,540(a0)
  myproc()->handler = addr;
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	7c2080e7          	jalr	1986(ra) # 80001a36 <myproc>
    8000327c:	fe843783          	ld	a5,-24(s0)
    80003280:	24f53823          	sd	a5,592(a0)

  return 0;
}
    80003284:	4501                	li	a0,0
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <sys_sigreturn>:


uint64 sys_sigreturn(void)
{
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	79e080e7          	jalr	1950(ra) # 80001a36 <myproc>
    800032a0:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    800032a2:	6605                	lui	a2,0x1
    800032a4:	22053583          	ld	a1,544(a0)
    800032a8:	7128                	ld	a0,96(a0)
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a84080e7          	jalr	-1404(ra) # 80000d2e <memmove>

  kfree(p->alarm_tf);
    800032b2:	2204b503          	ld	a0,544(s1)
    800032b6:	ffffd097          	auipc	ra,0xffffd
    800032ba:	734080e7          	jalr	1844(ra) # 800009ea <kfree>
  p->alarm_tf = 0;
    800032be:	2204b023          	sd	zero,544(s1)
  p->alarm_on = 0;
    800032c2:	2204a423          	sw	zero,552(s1)
  p->cur_ticks = 0;
    800032c6:	2004ae23          	sw	zero,540(s1)
  usertrapret();
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	6f6080e7          	jalr	1782(ra) # 800029c0 <usertrapret>
  return 0;
}
    800032d2:	4501                	li	a0,0
    800032d4:	60e2                	ld	ra,24(sp)
    800032d6:	6442                	ld	s0,16(sp)
    800032d8:	64a2                	ld	s1,8(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret

00000000800032de <sys_getreadcount>:
int
sys_getreadcount(void)
{
    800032de:	1141                	addi	sp,sp,-16
    800032e0:	e406                	sd	ra,8(sp)
    800032e2:	e022                	sd	s0,0(sp)
    800032e4:	0800                	addi	s0,sp,16
  return myproc()->readcallcount;
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	750080e7          	jalr	1872(ra) # 80001a36 <myproc>
}
    800032ee:	4128                	lw	a0,64(a0)
    800032f0:	60a2                	ld	ra,8(sp)
    800032f2:	6402                	ld	s0,0(sp)
    800032f4:	0141                	addi	sp,sp,16
    800032f6:	8082                	ret

00000000800032f8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032f8:	7179                	addi	sp,sp,-48
    800032fa:	f406                	sd	ra,40(sp)
    800032fc:	f022                	sd	s0,32(sp)
    800032fe:	ec26                	sd	s1,24(sp)
    80003300:	e84a                	sd	s2,16(sp)
    80003302:	e44e                	sd	s3,8(sp)
    80003304:	e052                	sd	s4,0(sp)
    80003306:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003308:	00005597          	auipc	a1,0x5
    8000330c:	21858593          	addi	a1,a1,536 # 80008520 <syscalls+0xd0>
    80003310:	00018517          	auipc	a0,0x18
    80003314:	ce850513          	addi	a0,a0,-792 # 8001aff8 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	82e080e7          	jalr	-2002(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003320:	00020797          	auipc	a5,0x20
    80003324:	cd878793          	addi	a5,a5,-808 # 80022ff8 <bcache+0x8000>
    80003328:	00020717          	auipc	a4,0x20
    8000332c:	f3870713          	addi	a4,a4,-200 # 80023260 <bcache+0x8268>
    80003330:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003334:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003338:	00018497          	auipc	s1,0x18
    8000333c:	cd848493          	addi	s1,s1,-808 # 8001b010 <bcache+0x18>
    b->next = bcache.head.next;
    80003340:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003342:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003344:	00005a17          	auipc	s4,0x5
    80003348:	1e4a0a13          	addi	s4,s4,484 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000334c:	2b893783          	ld	a5,696(s2)
    80003350:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003352:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003356:	85d2                	mv	a1,s4
    80003358:	01048513          	addi	a0,s1,16
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	4c4080e7          	jalr	1220(ra) # 80004820 <initsleeplock>
    bcache.head.next->prev = b;
    80003364:	2b893783          	ld	a5,696(s2)
    80003368:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000336a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000336e:	45848493          	addi	s1,s1,1112
    80003372:	fd349de3          	bne	s1,s3,8000334c <binit+0x54>
  }
}
    80003376:	70a2                	ld	ra,40(sp)
    80003378:	7402                	ld	s0,32(sp)
    8000337a:	64e2                	ld	s1,24(sp)
    8000337c:	6942                	ld	s2,16(sp)
    8000337e:	69a2                	ld	s3,8(sp)
    80003380:	6a02                	ld	s4,0(sp)
    80003382:	6145                	addi	sp,sp,48
    80003384:	8082                	ret

0000000080003386 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003386:	7179                	addi	sp,sp,-48
    80003388:	f406                	sd	ra,40(sp)
    8000338a:	f022                	sd	s0,32(sp)
    8000338c:	ec26                	sd	s1,24(sp)
    8000338e:	e84a                	sd	s2,16(sp)
    80003390:	e44e                	sd	s3,8(sp)
    80003392:	1800                	addi	s0,sp,48
    80003394:	892a                	mv	s2,a0
    80003396:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003398:	00018517          	auipc	a0,0x18
    8000339c:	c6050513          	addi	a0,a0,-928 # 8001aff8 <bcache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	836080e7          	jalr	-1994(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033a8:	00020497          	auipc	s1,0x20
    800033ac:	f084b483          	ld	s1,-248(s1) # 800232b0 <bcache+0x82b8>
    800033b0:	00020797          	auipc	a5,0x20
    800033b4:	eb078793          	addi	a5,a5,-336 # 80023260 <bcache+0x8268>
    800033b8:	02f48f63          	beq	s1,a5,800033f6 <bread+0x70>
    800033bc:	873e                	mv	a4,a5
    800033be:	a021                	j	800033c6 <bread+0x40>
    800033c0:	68a4                	ld	s1,80(s1)
    800033c2:	02e48a63          	beq	s1,a4,800033f6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033c6:	449c                	lw	a5,8(s1)
    800033c8:	ff279ce3          	bne	a5,s2,800033c0 <bread+0x3a>
    800033cc:	44dc                	lw	a5,12(s1)
    800033ce:	ff3799e3          	bne	a5,s3,800033c0 <bread+0x3a>
      b->refcnt++;
    800033d2:	40bc                	lw	a5,64(s1)
    800033d4:	2785                	addiw	a5,a5,1
    800033d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033d8:	00018517          	auipc	a0,0x18
    800033dc:	c2050513          	addi	a0,a0,-992 # 8001aff8 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800033e8:	01048513          	addi	a0,s1,16
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	46e080e7          	jalr	1134(ra) # 8000485a <acquiresleep>
      return b;
    800033f4:	a8b9                	j	80003452 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033f6:	00020497          	auipc	s1,0x20
    800033fa:	eb24b483          	ld	s1,-334(s1) # 800232a8 <bcache+0x82b0>
    800033fe:	00020797          	auipc	a5,0x20
    80003402:	e6278793          	addi	a5,a5,-414 # 80023260 <bcache+0x8268>
    80003406:	00f48863          	beq	s1,a5,80003416 <bread+0x90>
    8000340a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000340c:	40bc                	lw	a5,64(s1)
    8000340e:	cf81                	beqz	a5,80003426 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003410:	64a4                	ld	s1,72(s1)
    80003412:	fee49de3          	bne	s1,a4,8000340c <bread+0x86>
  panic("bget: no buffers");
    80003416:	00005517          	auipc	a0,0x5
    8000341a:	11a50513          	addi	a0,a0,282 # 80008530 <syscalls+0xe0>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	120080e7          	jalr	288(ra) # 8000053e <panic>
      b->dev = dev;
    80003426:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000342a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000342e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003432:	4785                	li	a5,1
    80003434:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003436:	00018517          	auipc	a0,0x18
    8000343a:	bc250513          	addi	a0,a0,-1086 # 8001aff8 <bcache>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	84c080e7          	jalr	-1972(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003446:	01048513          	addi	a0,s1,16
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	410080e7          	jalr	1040(ra) # 8000485a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003452:	409c                	lw	a5,0(s1)
    80003454:	cb89                	beqz	a5,80003466 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003456:	8526                	mv	a0,s1
    80003458:	70a2                	ld	ra,40(sp)
    8000345a:	7402                	ld	s0,32(sp)
    8000345c:	64e2                	ld	s1,24(sp)
    8000345e:	6942                	ld	s2,16(sp)
    80003460:	69a2                	ld	s3,8(sp)
    80003462:	6145                	addi	sp,sp,48
    80003464:	8082                	ret
    virtio_disk_rw(b, 0);
    80003466:	4581                	li	a1,0
    80003468:	8526                	mv	a0,s1
    8000346a:	00003097          	auipc	ra,0x3
    8000346e:	fda080e7          	jalr	-38(ra) # 80006444 <virtio_disk_rw>
    b->valid = 1;
    80003472:	4785                	li	a5,1
    80003474:	c09c                	sw	a5,0(s1)
  return b;
    80003476:	b7c5                	j	80003456 <bread+0xd0>

0000000080003478 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	1000                	addi	s0,sp,32
    80003482:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003484:	0541                	addi	a0,a0,16
    80003486:	00001097          	auipc	ra,0x1
    8000348a:	46e080e7          	jalr	1134(ra) # 800048f4 <holdingsleep>
    8000348e:	cd01                	beqz	a0,800034a6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003490:	4585                	li	a1,1
    80003492:	8526                	mv	a0,s1
    80003494:	00003097          	auipc	ra,0x3
    80003498:	fb0080e7          	jalr	-80(ra) # 80006444 <virtio_disk_rw>
}
    8000349c:	60e2                	ld	ra,24(sp)
    8000349e:	6442                	ld	s0,16(sp)
    800034a0:	64a2                	ld	s1,8(sp)
    800034a2:	6105                	addi	sp,sp,32
    800034a4:	8082                	ret
    panic("bwrite");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	0a250513          	addi	a0,a0,162 # 80008548 <syscalls+0xf8>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	090080e7          	jalr	144(ra) # 8000053e <panic>

00000000800034b6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	e04a                	sd	s2,0(sp)
    800034c0:	1000                	addi	s0,sp,32
    800034c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c4:	01050913          	addi	s2,a0,16
    800034c8:	854a                	mv	a0,s2
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	42a080e7          	jalr	1066(ra) # 800048f4 <holdingsleep>
    800034d2:	c92d                	beqz	a0,80003544 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034d4:	854a                	mv	a0,s2
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	3da080e7          	jalr	986(ra) # 800048b0 <releasesleep>

  acquire(&bcache.lock);
    800034de:	00018517          	auipc	a0,0x18
    800034e2:	b1a50513          	addi	a0,a0,-1254 # 8001aff8 <bcache>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	6f0080e7          	jalr	1776(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034ee:	40bc                	lw	a5,64(s1)
    800034f0:	37fd                	addiw	a5,a5,-1
    800034f2:	0007871b          	sext.w	a4,a5
    800034f6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034f8:	eb05                	bnez	a4,80003528 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034fa:	68bc                	ld	a5,80(s1)
    800034fc:	64b8                	ld	a4,72(s1)
    800034fe:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003500:	64bc                	ld	a5,72(s1)
    80003502:	68b8                	ld	a4,80(s1)
    80003504:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003506:	00020797          	auipc	a5,0x20
    8000350a:	af278793          	addi	a5,a5,-1294 # 80022ff8 <bcache+0x8000>
    8000350e:	2b87b703          	ld	a4,696(a5)
    80003512:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003514:	00020717          	auipc	a4,0x20
    80003518:	d4c70713          	addi	a4,a4,-692 # 80023260 <bcache+0x8268>
    8000351c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000351e:	2b87b703          	ld	a4,696(a5)
    80003522:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003524:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003528:	00018517          	auipc	a0,0x18
    8000352c:	ad050513          	addi	a0,a0,-1328 # 8001aff8 <bcache>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	75a080e7          	jalr	1882(ra) # 80000c8a <release>
}
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	64a2                	ld	s1,8(sp)
    8000353e:	6902                	ld	s2,0(sp)
    80003540:	6105                	addi	sp,sp,32
    80003542:	8082                	ret
    panic("brelse");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	00c50513          	addi	a0,a0,12 # 80008550 <syscalls+0x100>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>

0000000080003554 <bpin>:

void
bpin(struct buf *b) {
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	1000                	addi	s0,sp,32
    8000355e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003560:	00018517          	auipc	a0,0x18
    80003564:	a9850513          	addi	a0,a0,-1384 # 8001aff8 <bcache>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	66e080e7          	jalr	1646(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003570:	40bc                	lw	a5,64(s1)
    80003572:	2785                	addiw	a5,a5,1
    80003574:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003576:	00018517          	auipc	a0,0x18
    8000357a:	a8250513          	addi	a0,a0,-1406 # 8001aff8 <bcache>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	70c080e7          	jalr	1804(ra) # 80000c8a <release>
}
    80003586:	60e2                	ld	ra,24(sp)
    80003588:	6442                	ld	s0,16(sp)
    8000358a:	64a2                	ld	s1,8(sp)
    8000358c:	6105                	addi	sp,sp,32
    8000358e:	8082                	ret

0000000080003590 <bunpin>:

void
bunpin(struct buf *b) {
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	1000                	addi	s0,sp,32
    8000359a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000359c:	00018517          	auipc	a0,0x18
    800035a0:	a5c50513          	addi	a0,a0,-1444 # 8001aff8 <bcache>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	632080e7          	jalr	1586(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035ac:	40bc                	lw	a5,64(s1)
    800035ae:	37fd                	addiw	a5,a5,-1
    800035b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b2:	00018517          	auipc	a0,0x18
    800035b6:	a4650513          	addi	a0,a0,-1466 # 8001aff8 <bcache>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	6d0080e7          	jalr	1744(ra) # 80000c8a <release>
}
    800035c2:	60e2                	ld	ra,24(sp)
    800035c4:	6442                	ld	s0,16(sp)
    800035c6:	64a2                	ld	s1,8(sp)
    800035c8:	6105                	addi	sp,sp,32
    800035ca:	8082                	ret

00000000800035cc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035cc:	1101                	addi	sp,sp,-32
    800035ce:	ec06                	sd	ra,24(sp)
    800035d0:	e822                	sd	s0,16(sp)
    800035d2:	e426                	sd	s1,8(sp)
    800035d4:	e04a                	sd	s2,0(sp)
    800035d6:	1000                	addi	s0,sp,32
    800035d8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035da:	00d5d59b          	srliw	a1,a1,0xd
    800035de:	00020797          	auipc	a5,0x20
    800035e2:	0f67a783          	lw	a5,246(a5) # 800236d4 <sb+0x1c>
    800035e6:	9dbd                	addw	a1,a1,a5
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	d9e080e7          	jalr	-610(ra) # 80003386 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035f0:	0074f713          	andi	a4,s1,7
    800035f4:	4785                	li	a5,1
    800035f6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035fa:	14ce                	slli	s1,s1,0x33
    800035fc:	90d9                	srli	s1,s1,0x36
    800035fe:	00950733          	add	a4,a0,s1
    80003602:	05874703          	lbu	a4,88(a4)
    80003606:	00e7f6b3          	and	a3,a5,a4
    8000360a:	c69d                	beqz	a3,80003638 <bfree+0x6c>
    8000360c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000360e:	94aa                	add	s1,s1,a0
    80003610:	fff7c793          	not	a5,a5
    80003614:	8ff9                	and	a5,a5,a4
    80003616:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	120080e7          	jalr	288(ra) # 8000473a <log_write>
  brelse(bp);
    80003622:	854a                	mv	a0,s2
    80003624:	00000097          	auipc	ra,0x0
    80003628:	e92080e7          	jalr	-366(ra) # 800034b6 <brelse>
}
    8000362c:	60e2                	ld	ra,24(sp)
    8000362e:	6442                	ld	s0,16(sp)
    80003630:	64a2                	ld	s1,8(sp)
    80003632:	6902                	ld	s2,0(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret
    panic("freeing free block");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	f2050513          	addi	a0,a0,-224 # 80008558 <syscalls+0x108>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>

0000000080003648 <balloc>:
{
    80003648:	711d                	addi	sp,sp,-96
    8000364a:	ec86                	sd	ra,88(sp)
    8000364c:	e8a2                	sd	s0,80(sp)
    8000364e:	e4a6                	sd	s1,72(sp)
    80003650:	e0ca                	sd	s2,64(sp)
    80003652:	fc4e                	sd	s3,56(sp)
    80003654:	f852                	sd	s4,48(sp)
    80003656:	f456                	sd	s5,40(sp)
    80003658:	f05a                	sd	s6,32(sp)
    8000365a:	ec5e                	sd	s7,24(sp)
    8000365c:	e862                	sd	s8,16(sp)
    8000365e:	e466                	sd	s9,8(sp)
    80003660:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003662:	00020797          	auipc	a5,0x20
    80003666:	05a7a783          	lw	a5,90(a5) # 800236bc <sb+0x4>
    8000366a:	10078163          	beqz	a5,8000376c <balloc+0x124>
    8000366e:	8baa                	mv	s7,a0
    80003670:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003672:	00020b17          	auipc	s6,0x20
    80003676:	046b0b13          	addi	s6,s6,70 # 800236b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000367a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000367c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000367e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003680:	6c89                	lui	s9,0x2
    80003682:	a061                	j	8000370a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003684:	974a                	add	a4,a4,s2
    80003686:	8fd5                	or	a5,a5,a3
    80003688:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000368c:	854a                	mv	a0,s2
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	0ac080e7          	jalr	172(ra) # 8000473a <log_write>
        brelse(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	e1e080e7          	jalr	-482(ra) # 800034b6 <brelse>
  bp = bread(dev, bno);
    800036a0:	85a6                	mv	a1,s1
    800036a2:	855e                	mv	a0,s7
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	ce2080e7          	jalr	-798(ra) # 80003386 <bread>
    800036ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036ae:	40000613          	li	a2,1024
    800036b2:	4581                	li	a1,0
    800036b4:	05850513          	addi	a0,a0,88
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	61a080e7          	jalr	1562(ra) # 80000cd2 <memset>
  log_write(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	078080e7          	jalr	120(ra) # 8000473a <log_write>
  brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	dea080e7          	jalr	-534(ra) # 800034b6 <brelse>
}
    800036d4:	8526                	mv	a0,s1
    800036d6:	60e6                	ld	ra,88(sp)
    800036d8:	6446                	ld	s0,80(sp)
    800036da:	64a6                	ld	s1,72(sp)
    800036dc:	6906                	ld	s2,64(sp)
    800036de:	79e2                	ld	s3,56(sp)
    800036e0:	7a42                	ld	s4,48(sp)
    800036e2:	7aa2                	ld	s5,40(sp)
    800036e4:	7b02                	ld	s6,32(sp)
    800036e6:	6be2                	ld	s7,24(sp)
    800036e8:	6c42                	ld	s8,16(sp)
    800036ea:	6ca2                	ld	s9,8(sp)
    800036ec:	6125                	addi	sp,sp,96
    800036ee:	8082                	ret
    brelse(bp);
    800036f0:	854a                	mv	a0,s2
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	dc4080e7          	jalr	-572(ra) # 800034b6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036fa:	015c87bb          	addw	a5,s9,s5
    800036fe:	00078a9b          	sext.w	s5,a5
    80003702:	004b2703          	lw	a4,4(s6)
    80003706:	06eaf363          	bgeu	s5,a4,8000376c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000370a:	41fad79b          	sraiw	a5,s5,0x1f
    8000370e:	0137d79b          	srliw	a5,a5,0x13
    80003712:	015787bb          	addw	a5,a5,s5
    80003716:	40d7d79b          	sraiw	a5,a5,0xd
    8000371a:	01cb2583          	lw	a1,28(s6)
    8000371e:	9dbd                	addw	a1,a1,a5
    80003720:	855e                	mv	a0,s7
    80003722:	00000097          	auipc	ra,0x0
    80003726:	c64080e7          	jalr	-924(ra) # 80003386 <bread>
    8000372a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372c:	004b2503          	lw	a0,4(s6)
    80003730:	000a849b          	sext.w	s1,s5
    80003734:	8662                	mv	a2,s8
    80003736:	faa4fde3          	bgeu	s1,a0,800036f0 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000373a:	41f6579b          	sraiw	a5,a2,0x1f
    8000373e:	01d7d69b          	srliw	a3,a5,0x1d
    80003742:	00c6873b          	addw	a4,a3,a2
    80003746:	00777793          	andi	a5,a4,7
    8000374a:	9f95                	subw	a5,a5,a3
    8000374c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003750:	4037571b          	sraiw	a4,a4,0x3
    80003754:	00e906b3          	add	a3,s2,a4
    80003758:	0586c683          	lbu	a3,88(a3)
    8000375c:	00d7f5b3          	and	a1,a5,a3
    80003760:	d195                	beqz	a1,80003684 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003762:	2605                	addiw	a2,a2,1
    80003764:	2485                	addiw	s1,s1,1
    80003766:	fd4618e3          	bne	a2,s4,80003736 <balloc+0xee>
    8000376a:	b759                	j	800036f0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000376c:	00005517          	auipc	a0,0x5
    80003770:	e0450513          	addi	a0,a0,-508 # 80008570 <syscalls+0x120>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	e14080e7          	jalr	-492(ra) # 80000588 <printf>
  return 0;
    8000377c:	4481                	li	s1,0
    8000377e:	bf99                	j	800036d4 <balloc+0x8c>

0000000080003780 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003780:	7179                	addi	sp,sp,-48
    80003782:	f406                	sd	ra,40(sp)
    80003784:	f022                	sd	s0,32(sp)
    80003786:	ec26                	sd	s1,24(sp)
    80003788:	e84a                	sd	s2,16(sp)
    8000378a:	e44e                	sd	s3,8(sp)
    8000378c:	e052                	sd	s4,0(sp)
    8000378e:	1800                	addi	s0,sp,48
    80003790:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003792:	47ad                	li	a5,11
    80003794:	02b7e763          	bltu	a5,a1,800037c2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003798:	02059493          	slli	s1,a1,0x20
    8000379c:	9081                	srli	s1,s1,0x20
    8000379e:	048a                	slli	s1,s1,0x2
    800037a0:	94aa                	add	s1,s1,a0
    800037a2:	0504a903          	lw	s2,80(s1)
    800037a6:	06091e63          	bnez	s2,80003822 <bmap+0xa2>
      addr = balloc(ip->dev);
    800037aa:	4108                	lw	a0,0(a0)
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	e9c080e7          	jalr	-356(ra) # 80003648 <balloc>
    800037b4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037b8:	06090563          	beqz	s2,80003822 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800037bc:	0524a823          	sw	s2,80(s1)
    800037c0:	a08d                	j	80003822 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037c2:	ff45849b          	addiw	s1,a1,-12
    800037c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037ca:	0ff00793          	li	a5,255
    800037ce:	08e7e563          	bltu	a5,a4,80003858 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037d2:	08052903          	lw	s2,128(a0)
    800037d6:	00091d63          	bnez	s2,800037f0 <bmap+0x70>
      addr = balloc(ip->dev);
    800037da:	4108                	lw	a0,0(a0)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	e6c080e7          	jalr	-404(ra) # 80003648 <balloc>
    800037e4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037e8:	02090d63          	beqz	s2,80003822 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037ec:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037f0:	85ca                	mv	a1,s2
    800037f2:	0009a503          	lw	a0,0(s3)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	b90080e7          	jalr	-1136(ra) # 80003386 <bread>
    800037fe:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003800:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003804:	02049593          	slli	a1,s1,0x20
    80003808:	9181                	srli	a1,a1,0x20
    8000380a:	058a                	slli	a1,a1,0x2
    8000380c:	00b784b3          	add	s1,a5,a1
    80003810:	0004a903          	lw	s2,0(s1)
    80003814:	02090063          	beqz	s2,80003834 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003818:	8552                	mv	a0,s4
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	c9c080e7          	jalr	-868(ra) # 800034b6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003822:	854a                	mv	a0,s2
    80003824:	70a2                	ld	ra,40(sp)
    80003826:	7402                	ld	s0,32(sp)
    80003828:	64e2                	ld	s1,24(sp)
    8000382a:	6942                	ld	s2,16(sp)
    8000382c:	69a2                	ld	s3,8(sp)
    8000382e:	6a02                	ld	s4,0(sp)
    80003830:	6145                	addi	sp,sp,48
    80003832:	8082                	ret
      addr = balloc(ip->dev);
    80003834:	0009a503          	lw	a0,0(s3)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	e10080e7          	jalr	-496(ra) # 80003648 <balloc>
    80003840:	0005091b          	sext.w	s2,a0
      if(addr){
    80003844:	fc090ae3          	beqz	s2,80003818 <bmap+0x98>
        a[bn] = addr;
    80003848:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000384c:	8552                	mv	a0,s4
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	eec080e7          	jalr	-276(ra) # 8000473a <log_write>
    80003856:	b7c9                	j	80003818 <bmap+0x98>
  panic("bmap: out of range");
    80003858:	00005517          	auipc	a0,0x5
    8000385c:	d3050513          	addi	a0,a0,-720 # 80008588 <syscalls+0x138>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>

0000000080003868 <iget>:
{
    80003868:	7179                	addi	sp,sp,-48
    8000386a:	f406                	sd	ra,40(sp)
    8000386c:	f022                	sd	s0,32(sp)
    8000386e:	ec26                	sd	s1,24(sp)
    80003870:	e84a                	sd	s2,16(sp)
    80003872:	e44e                	sd	s3,8(sp)
    80003874:	e052                	sd	s4,0(sp)
    80003876:	1800                	addi	s0,sp,48
    80003878:	89aa                	mv	s3,a0
    8000387a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000387c:	00020517          	auipc	a0,0x20
    80003880:	e5c50513          	addi	a0,a0,-420 # 800236d8 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	352080e7          	jalr	850(ra) # 80000bd6 <acquire>
  empty = 0;
    8000388c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000388e:	00020497          	auipc	s1,0x20
    80003892:	e6248493          	addi	s1,s1,-414 # 800236f0 <itable+0x18>
    80003896:	00022697          	auipc	a3,0x22
    8000389a:	8ea68693          	addi	a3,a3,-1814 # 80025180 <log>
    8000389e:	a039                	j	800038ac <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038a0:	02090b63          	beqz	s2,800038d6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038a4:	08848493          	addi	s1,s1,136
    800038a8:	02d48a63          	beq	s1,a3,800038dc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ac:	449c                	lw	a5,8(s1)
    800038ae:	fef059e3          	blez	a5,800038a0 <iget+0x38>
    800038b2:	4098                	lw	a4,0(s1)
    800038b4:	ff3716e3          	bne	a4,s3,800038a0 <iget+0x38>
    800038b8:	40d8                	lw	a4,4(s1)
    800038ba:	ff4713e3          	bne	a4,s4,800038a0 <iget+0x38>
      ip->ref++;
    800038be:	2785                	addiw	a5,a5,1
    800038c0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038c2:	00020517          	auipc	a0,0x20
    800038c6:	e1650513          	addi	a0,a0,-490 # 800236d8 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3c0080e7          	jalr	960(ra) # 80000c8a <release>
      return ip;
    800038d2:	8926                	mv	s2,s1
    800038d4:	a03d                	j	80003902 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d6:	f7f9                	bnez	a5,800038a4 <iget+0x3c>
    800038d8:	8926                	mv	s2,s1
    800038da:	b7e9                	j	800038a4 <iget+0x3c>
  if(empty == 0)
    800038dc:	02090c63          	beqz	s2,80003914 <iget+0xac>
  ip->dev = dev;
    800038e0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038e4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038e8:	4785                	li	a5,1
    800038ea:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ee:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038f2:	00020517          	auipc	a0,0x20
    800038f6:	de650513          	addi	a0,a0,-538 # 800236d8 <itable>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	390080e7          	jalr	912(ra) # 80000c8a <release>
}
    80003902:	854a                	mv	a0,s2
    80003904:	70a2                	ld	ra,40(sp)
    80003906:	7402                	ld	s0,32(sp)
    80003908:	64e2                	ld	s1,24(sp)
    8000390a:	6942                	ld	s2,16(sp)
    8000390c:	69a2                	ld	s3,8(sp)
    8000390e:	6a02                	ld	s4,0(sp)
    80003910:	6145                	addi	sp,sp,48
    80003912:	8082                	ret
    panic("iget: no inodes");
    80003914:	00005517          	auipc	a0,0x5
    80003918:	c8c50513          	addi	a0,a0,-884 # 800085a0 <syscalls+0x150>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	c22080e7          	jalr	-990(ra) # 8000053e <panic>

0000000080003924 <fsinit>:
fsinit(int dev) {
    80003924:	7179                	addi	sp,sp,-48
    80003926:	f406                	sd	ra,40(sp)
    80003928:	f022                	sd	s0,32(sp)
    8000392a:	ec26                	sd	s1,24(sp)
    8000392c:	e84a                	sd	s2,16(sp)
    8000392e:	e44e                	sd	s3,8(sp)
    80003930:	1800                	addi	s0,sp,48
    80003932:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003934:	4585                	li	a1,1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	a50080e7          	jalr	-1456(ra) # 80003386 <bread>
    8000393e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003940:	00020997          	auipc	s3,0x20
    80003944:	d7898993          	addi	s3,s3,-648 # 800236b8 <sb>
    80003948:	02000613          	li	a2,32
    8000394c:	05850593          	addi	a1,a0,88
    80003950:	854e                	mv	a0,s3
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	3dc080e7          	jalr	988(ra) # 80000d2e <memmove>
  brelse(bp);
    8000395a:	8526                	mv	a0,s1
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	b5a080e7          	jalr	-1190(ra) # 800034b6 <brelse>
  if(sb.magic != FSMAGIC)
    80003964:	0009a703          	lw	a4,0(s3)
    80003968:	102037b7          	lui	a5,0x10203
    8000396c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003970:	02f71263          	bne	a4,a5,80003994 <fsinit+0x70>
  initlog(dev, &sb);
    80003974:	00020597          	auipc	a1,0x20
    80003978:	d4458593          	addi	a1,a1,-700 # 800236b8 <sb>
    8000397c:	854a                	mv	a0,s2
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	b40080e7          	jalr	-1216(ra) # 800044be <initlog>
}
    80003986:	70a2                	ld	ra,40(sp)
    80003988:	7402                	ld	s0,32(sp)
    8000398a:	64e2                	ld	s1,24(sp)
    8000398c:	6942                	ld	s2,16(sp)
    8000398e:	69a2                	ld	s3,8(sp)
    80003990:	6145                	addi	sp,sp,48
    80003992:	8082                	ret
    panic("invalid file system");
    80003994:	00005517          	auipc	a0,0x5
    80003998:	c1c50513          	addi	a0,a0,-996 # 800085b0 <syscalls+0x160>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	ba2080e7          	jalr	-1118(ra) # 8000053e <panic>

00000000800039a4 <iinit>:
{
    800039a4:	7179                	addi	sp,sp,-48
    800039a6:	f406                	sd	ra,40(sp)
    800039a8:	f022                	sd	s0,32(sp)
    800039aa:	ec26                	sd	s1,24(sp)
    800039ac:	e84a                	sd	s2,16(sp)
    800039ae:	e44e                	sd	s3,8(sp)
    800039b0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039b2:	00005597          	auipc	a1,0x5
    800039b6:	c1658593          	addi	a1,a1,-1002 # 800085c8 <syscalls+0x178>
    800039ba:	00020517          	auipc	a0,0x20
    800039be:	d1e50513          	addi	a0,a0,-738 # 800236d8 <itable>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	184080e7          	jalr	388(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ca:	00020497          	auipc	s1,0x20
    800039ce:	d3648493          	addi	s1,s1,-714 # 80023700 <itable+0x28>
    800039d2:	00021997          	auipc	s3,0x21
    800039d6:	7be98993          	addi	s3,s3,1982 # 80025190 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039da:	00005917          	auipc	s2,0x5
    800039de:	bf690913          	addi	s2,s2,-1034 # 800085d0 <syscalls+0x180>
    800039e2:	85ca                	mv	a1,s2
    800039e4:	8526                	mv	a0,s1
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	e3a080e7          	jalr	-454(ra) # 80004820 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ee:	08848493          	addi	s1,s1,136
    800039f2:	ff3498e3          	bne	s1,s3,800039e2 <iinit+0x3e>
}
    800039f6:	70a2                	ld	ra,40(sp)
    800039f8:	7402                	ld	s0,32(sp)
    800039fa:	64e2                	ld	s1,24(sp)
    800039fc:	6942                	ld	s2,16(sp)
    800039fe:	69a2                	ld	s3,8(sp)
    80003a00:	6145                	addi	sp,sp,48
    80003a02:	8082                	ret

0000000080003a04 <ialloc>:
{
    80003a04:	715d                	addi	sp,sp,-80
    80003a06:	e486                	sd	ra,72(sp)
    80003a08:	e0a2                	sd	s0,64(sp)
    80003a0a:	fc26                	sd	s1,56(sp)
    80003a0c:	f84a                	sd	s2,48(sp)
    80003a0e:	f44e                	sd	s3,40(sp)
    80003a10:	f052                	sd	s4,32(sp)
    80003a12:	ec56                	sd	s5,24(sp)
    80003a14:	e85a                	sd	s6,16(sp)
    80003a16:	e45e                	sd	s7,8(sp)
    80003a18:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a1a:	00020717          	auipc	a4,0x20
    80003a1e:	caa72703          	lw	a4,-854(a4) # 800236c4 <sb+0xc>
    80003a22:	4785                	li	a5,1
    80003a24:	04e7fa63          	bgeu	a5,a4,80003a78 <ialloc+0x74>
    80003a28:	8aaa                	mv	s5,a0
    80003a2a:	8bae                	mv	s7,a1
    80003a2c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a2e:	00020a17          	auipc	s4,0x20
    80003a32:	c8aa0a13          	addi	s4,s4,-886 # 800236b8 <sb>
    80003a36:	00048b1b          	sext.w	s6,s1
    80003a3a:	0044d793          	srli	a5,s1,0x4
    80003a3e:	018a2583          	lw	a1,24(s4)
    80003a42:	9dbd                	addw	a1,a1,a5
    80003a44:	8556                	mv	a0,s5
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	940080e7          	jalr	-1728(ra) # 80003386 <bread>
    80003a4e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a50:	05850993          	addi	s3,a0,88
    80003a54:	00f4f793          	andi	a5,s1,15
    80003a58:	079a                	slli	a5,a5,0x6
    80003a5a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a5c:	00099783          	lh	a5,0(s3)
    80003a60:	c3a1                	beqz	a5,80003aa0 <ialloc+0x9c>
    brelse(bp);
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	a54080e7          	jalr	-1452(ra) # 800034b6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a6a:	0485                	addi	s1,s1,1
    80003a6c:	00ca2703          	lw	a4,12(s4)
    80003a70:	0004879b          	sext.w	a5,s1
    80003a74:	fce7e1e3          	bltu	a5,a4,80003a36 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	b6050513          	addi	a0,a0,-1184 # 800085d8 <syscalls+0x188>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	b08080e7          	jalr	-1272(ra) # 80000588 <printf>
  return 0;
    80003a88:	4501                	li	a0,0
}
    80003a8a:	60a6                	ld	ra,72(sp)
    80003a8c:	6406                	ld	s0,64(sp)
    80003a8e:	74e2                	ld	s1,56(sp)
    80003a90:	7942                	ld	s2,48(sp)
    80003a92:	79a2                	ld	s3,40(sp)
    80003a94:	7a02                	ld	s4,32(sp)
    80003a96:	6ae2                	ld	s5,24(sp)
    80003a98:	6b42                	ld	s6,16(sp)
    80003a9a:	6ba2                	ld	s7,8(sp)
    80003a9c:	6161                	addi	sp,sp,80
    80003a9e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003aa0:	04000613          	li	a2,64
    80003aa4:	4581                	li	a1,0
    80003aa6:	854e                	mv	a0,s3
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	22a080e7          	jalr	554(ra) # 80000cd2 <memset>
      dip->type = type;
    80003ab0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	00001097          	auipc	ra,0x1
    80003aba:	c84080e7          	jalr	-892(ra) # 8000473a <log_write>
      brelse(bp);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	9f6080e7          	jalr	-1546(ra) # 800034b6 <brelse>
      return iget(dev, inum);
    80003ac8:	85da                	mv	a1,s6
    80003aca:	8556                	mv	a0,s5
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	d9c080e7          	jalr	-612(ra) # 80003868 <iget>
    80003ad4:	bf5d                	j	80003a8a <ialloc+0x86>

0000000080003ad6 <iupdate>:
{
    80003ad6:	1101                	addi	sp,sp,-32
    80003ad8:	ec06                	sd	ra,24(sp)
    80003ada:	e822                	sd	s0,16(sp)
    80003adc:	e426                	sd	s1,8(sp)
    80003ade:	e04a                	sd	s2,0(sp)
    80003ae0:	1000                	addi	s0,sp,32
    80003ae2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ae4:	415c                	lw	a5,4(a0)
    80003ae6:	0047d79b          	srliw	a5,a5,0x4
    80003aea:	00020597          	auipc	a1,0x20
    80003aee:	be65a583          	lw	a1,-1050(a1) # 800236d0 <sb+0x18>
    80003af2:	9dbd                	addw	a1,a1,a5
    80003af4:	4108                	lw	a0,0(a0)
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	890080e7          	jalr	-1904(ra) # 80003386 <bread>
    80003afe:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b00:	05850793          	addi	a5,a0,88
    80003b04:	40c8                	lw	a0,4(s1)
    80003b06:	893d                	andi	a0,a0,15
    80003b08:	051a                	slli	a0,a0,0x6
    80003b0a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b0c:	04449703          	lh	a4,68(s1)
    80003b10:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b14:	04649703          	lh	a4,70(s1)
    80003b18:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b1c:	04849703          	lh	a4,72(s1)
    80003b20:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b24:	04a49703          	lh	a4,74(s1)
    80003b28:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b2c:	44f8                	lw	a4,76(s1)
    80003b2e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b30:	03400613          	li	a2,52
    80003b34:	05048593          	addi	a1,s1,80
    80003b38:	0531                	addi	a0,a0,12
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	1f4080e7          	jalr	500(ra) # 80000d2e <memmove>
  log_write(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	bf6080e7          	jalr	-1034(ra) # 8000473a <log_write>
  brelse(bp);
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	968080e7          	jalr	-1688(ra) # 800034b6 <brelse>
}
    80003b56:	60e2                	ld	ra,24(sp)
    80003b58:	6442                	ld	s0,16(sp)
    80003b5a:	64a2                	ld	s1,8(sp)
    80003b5c:	6902                	ld	s2,0(sp)
    80003b5e:	6105                	addi	sp,sp,32
    80003b60:	8082                	ret

0000000080003b62 <idup>:
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b6e:	00020517          	auipc	a0,0x20
    80003b72:	b6a50513          	addi	a0,a0,-1174 # 800236d8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	060080e7          	jalr	96(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003b7e:	449c                	lw	a5,8(s1)
    80003b80:	2785                	addiw	a5,a5,1
    80003b82:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b84:	00020517          	auipc	a0,0x20
    80003b88:	b5450513          	addi	a0,a0,-1196 # 800236d8 <itable>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	0fe080e7          	jalr	254(ra) # 80000c8a <release>
}
    80003b94:	8526                	mv	a0,s1
    80003b96:	60e2                	ld	ra,24(sp)
    80003b98:	6442                	ld	s0,16(sp)
    80003b9a:	64a2                	ld	s1,8(sp)
    80003b9c:	6105                	addi	sp,sp,32
    80003b9e:	8082                	ret

0000000080003ba0 <ilock>:
{
    80003ba0:	1101                	addi	sp,sp,-32
    80003ba2:	ec06                	sd	ra,24(sp)
    80003ba4:	e822                	sd	s0,16(sp)
    80003ba6:	e426                	sd	s1,8(sp)
    80003ba8:	e04a                	sd	s2,0(sp)
    80003baa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bac:	c115                	beqz	a0,80003bd0 <ilock+0x30>
    80003bae:	84aa                	mv	s1,a0
    80003bb0:	451c                	lw	a5,8(a0)
    80003bb2:	00f05f63          	blez	a5,80003bd0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bb6:	0541                	addi	a0,a0,16
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	ca2080e7          	jalr	-862(ra) # 8000485a <acquiresleep>
  if(ip->valid == 0){
    80003bc0:	40bc                	lw	a5,64(s1)
    80003bc2:	cf99                	beqz	a5,80003be0 <ilock+0x40>
}
    80003bc4:	60e2                	ld	ra,24(sp)
    80003bc6:	6442                	ld	s0,16(sp)
    80003bc8:	64a2                	ld	s1,8(sp)
    80003bca:	6902                	ld	s2,0(sp)
    80003bcc:	6105                	addi	sp,sp,32
    80003bce:	8082                	ret
    panic("ilock");
    80003bd0:	00005517          	auipc	a0,0x5
    80003bd4:	a2050513          	addi	a0,a0,-1504 # 800085f0 <syscalls+0x1a0>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	966080e7          	jalr	-1690(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003be0:	40dc                	lw	a5,4(s1)
    80003be2:	0047d79b          	srliw	a5,a5,0x4
    80003be6:	00020597          	auipc	a1,0x20
    80003bea:	aea5a583          	lw	a1,-1302(a1) # 800236d0 <sb+0x18>
    80003bee:	9dbd                	addw	a1,a1,a5
    80003bf0:	4088                	lw	a0,0(s1)
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	794080e7          	jalr	1940(ra) # 80003386 <bread>
    80003bfa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bfc:	05850593          	addi	a1,a0,88
    80003c00:	40dc                	lw	a5,4(s1)
    80003c02:	8bbd                	andi	a5,a5,15
    80003c04:	079a                	slli	a5,a5,0x6
    80003c06:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c08:	00059783          	lh	a5,0(a1)
    80003c0c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c10:	00259783          	lh	a5,2(a1)
    80003c14:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c18:	00459783          	lh	a5,4(a1)
    80003c1c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c20:	00659783          	lh	a5,6(a1)
    80003c24:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c28:	459c                	lw	a5,8(a1)
    80003c2a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c2c:	03400613          	li	a2,52
    80003c30:	05b1                	addi	a1,a1,12
    80003c32:	05048513          	addi	a0,s1,80
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	0f8080e7          	jalr	248(ra) # 80000d2e <memmove>
    brelse(bp);
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	876080e7          	jalr	-1930(ra) # 800034b6 <brelse>
    ip->valid = 1;
    80003c48:	4785                	li	a5,1
    80003c4a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c4c:	04449783          	lh	a5,68(s1)
    80003c50:	fbb5                	bnez	a5,80003bc4 <ilock+0x24>
      panic("ilock: no type");
    80003c52:	00005517          	auipc	a0,0x5
    80003c56:	9a650513          	addi	a0,a0,-1626 # 800085f8 <syscalls+0x1a8>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>

0000000080003c62 <iunlock>:
{
    80003c62:	1101                	addi	sp,sp,-32
    80003c64:	ec06                	sd	ra,24(sp)
    80003c66:	e822                	sd	s0,16(sp)
    80003c68:	e426                	sd	s1,8(sp)
    80003c6a:	e04a                	sd	s2,0(sp)
    80003c6c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c6e:	c905                	beqz	a0,80003c9e <iunlock+0x3c>
    80003c70:	84aa                	mv	s1,a0
    80003c72:	01050913          	addi	s2,a0,16
    80003c76:	854a                	mv	a0,s2
    80003c78:	00001097          	auipc	ra,0x1
    80003c7c:	c7c080e7          	jalr	-900(ra) # 800048f4 <holdingsleep>
    80003c80:	cd19                	beqz	a0,80003c9e <iunlock+0x3c>
    80003c82:	449c                	lw	a5,8(s1)
    80003c84:	00f05d63          	blez	a5,80003c9e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	00001097          	auipc	ra,0x1
    80003c8e:	c26080e7          	jalr	-986(ra) # 800048b0 <releasesleep>
}
    80003c92:	60e2                	ld	ra,24(sp)
    80003c94:	6442                	ld	s0,16(sp)
    80003c96:	64a2                	ld	s1,8(sp)
    80003c98:	6902                	ld	s2,0(sp)
    80003c9a:	6105                	addi	sp,sp,32
    80003c9c:	8082                	ret
    panic("iunlock");
    80003c9e:	00005517          	auipc	a0,0x5
    80003ca2:	96a50513          	addi	a0,a0,-1686 # 80008608 <syscalls+0x1b8>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	898080e7          	jalr	-1896(ra) # 8000053e <panic>

0000000080003cae <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cae:	7179                	addi	sp,sp,-48
    80003cb0:	f406                	sd	ra,40(sp)
    80003cb2:	f022                	sd	s0,32(sp)
    80003cb4:	ec26                	sd	s1,24(sp)
    80003cb6:	e84a                	sd	s2,16(sp)
    80003cb8:	e44e                	sd	s3,8(sp)
    80003cba:	e052                	sd	s4,0(sp)
    80003cbc:	1800                	addi	s0,sp,48
    80003cbe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cc0:	05050493          	addi	s1,a0,80
    80003cc4:	08050913          	addi	s2,a0,128
    80003cc8:	a021                	j	80003cd0 <itrunc+0x22>
    80003cca:	0491                	addi	s1,s1,4
    80003ccc:	01248d63          	beq	s1,s2,80003ce6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cd0:	408c                	lw	a1,0(s1)
    80003cd2:	dde5                	beqz	a1,80003cca <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cd4:	0009a503          	lw	a0,0(s3)
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	8f4080e7          	jalr	-1804(ra) # 800035cc <bfree>
      ip->addrs[i] = 0;
    80003ce0:	0004a023          	sw	zero,0(s1)
    80003ce4:	b7dd                	j	80003cca <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ce6:	0809a583          	lw	a1,128(s3)
    80003cea:	e185                	bnez	a1,80003d0a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cec:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cf0:	854e                	mv	a0,s3
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	de4080e7          	jalr	-540(ra) # 80003ad6 <iupdate>
}
    80003cfa:	70a2                	ld	ra,40(sp)
    80003cfc:	7402                	ld	s0,32(sp)
    80003cfe:	64e2                	ld	s1,24(sp)
    80003d00:	6942                	ld	s2,16(sp)
    80003d02:	69a2                	ld	s3,8(sp)
    80003d04:	6a02                	ld	s4,0(sp)
    80003d06:	6145                	addi	sp,sp,48
    80003d08:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d0a:	0009a503          	lw	a0,0(s3)
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	678080e7          	jalr	1656(ra) # 80003386 <bread>
    80003d16:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d18:	05850493          	addi	s1,a0,88
    80003d1c:	45850913          	addi	s2,a0,1112
    80003d20:	a021                	j	80003d28 <itrunc+0x7a>
    80003d22:	0491                	addi	s1,s1,4
    80003d24:	01248b63          	beq	s1,s2,80003d3a <itrunc+0x8c>
      if(a[j])
    80003d28:	408c                	lw	a1,0(s1)
    80003d2a:	dde5                	beqz	a1,80003d22 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d2c:	0009a503          	lw	a0,0(s3)
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	89c080e7          	jalr	-1892(ra) # 800035cc <bfree>
    80003d38:	b7ed                	j	80003d22 <itrunc+0x74>
    brelse(bp);
    80003d3a:	8552                	mv	a0,s4
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	77a080e7          	jalr	1914(ra) # 800034b6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d44:	0809a583          	lw	a1,128(s3)
    80003d48:	0009a503          	lw	a0,0(s3)
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	880080e7          	jalr	-1920(ra) # 800035cc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d54:	0809a023          	sw	zero,128(s3)
    80003d58:	bf51                	j	80003cec <itrunc+0x3e>

0000000080003d5a <iput>:
{
    80003d5a:	1101                	addi	sp,sp,-32
    80003d5c:	ec06                	sd	ra,24(sp)
    80003d5e:	e822                	sd	s0,16(sp)
    80003d60:	e426                	sd	s1,8(sp)
    80003d62:	e04a                	sd	s2,0(sp)
    80003d64:	1000                	addi	s0,sp,32
    80003d66:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d68:	00020517          	auipc	a0,0x20
    80003d6c:	97050513          	addi	a0,a0,-1680 # 800236d8 <itable>
    80003d70:	ffffd097          	auipc	ra,0xffffd
    80003d74:	e66080e7          	jalr	-410(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d78:	4498                	lw	a4,8(s1)
    80003d7a:	4785                	li	a5,1
    80003d7c:	02f70363          	beq	a4,a5,80003da2 <iput+0x48>
  ip->ref--;
    80003d80:	449c                	lw	a5,8(s1)
    80003d82:	37fd                	addiw	a5,a5,-1
    80003d84:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d86:	00020517          	auipc	a0,0x20
    80003d8a:	95250513          	addi	a0,a0,-1710 # 800236d8 <itable>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	efc080e7          	jalr	-260(ra) # 80000c8a <release>
}
    80003d96:	60e2                	ld	ra,24(sp)
    80003d98:	6442                	ld	s0,16(sp)
    80003d9a:	64a2                	ld	s1,8(sp)
    80003d9c:	6902                	ld	s2,0(sp)
    80003d9e:	6105                	addi	sp,sp,32
    80003da0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003da2:	40bc                	lw	a5,64(s1)
    80003da4:	dff1                	beqz	a5,80003d80 <iput+0x26>
    80003da6:	04a49783          	lh	a5,74(s1)
    80003daa:	fbf9                	bnez	a5,80003d80 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dac:	01048913          	addi	s2,s1,16
    80003db0:	854a                	mv	a0,s2
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	aa8080e7          	jalr	-1368(ra) # 8000485a <acquiresleep>
    release(&itable.lock);
    80003dba:	00020517          	auipc	a0,0x20
    80003dbe:	91e50513          	addi	a0,a0,-1762 # 800236d8 <itable>
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	ec8080e7          	jalr	-312(ra) # 80000c8a <release>
    itrunc(ip);
    80003dca:	8526                	mv	a0,s1
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	ee2080e7          	jalr	-286(ra) # 80003cae <itrunc>
    ip->type = 0;
    80003dd4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	cfc080e7          	jalr	-772(ra) # 80003ad6 <iupdate>
    ip->valid = 0;
    80003de2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003de6:	854a                	mv	a0,s2
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	ac8080e7          	jalr	-1336(ra) # 800048b0 <releasesleep>
    acquire(&itable.lock);
    80003df0:	00020517          	auipc	a0,0x20
    80003df4:	8e850513          	addi	a0,a0,-1816 # 800236d8 <itable>
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	dde080e7          	jalr	-546(ra) # 80000bd6 <acquire>
    80003e00:	b741                	j	80003d80 <iput+0x26>

0000000080003e02 <iunlockput>:
{
    80003e02:	1101                	addi	sp,sp,-32
    80003e04:	ec06                	sd	ra,24(sp)
    80003e06:	e822                	sd	s0,16(sp)
    80003e08:	e426                	sd	s1,8(sp)
    80003e0a:	1000                	addi	s0,sp,32
    80003e0c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	e54080e7          	jalr	-428(ra) # 80003c62 <iunlock>
  iput(ip);
    80003e16:	8526                	mv	a0,s1
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	f42080e7          	jalr	-190(ra) # 80003d5a <iput>
}
    80003e20:	60e2                	ld	ra,24(sp)
    80003e22:	6442                	ld	s0,16(sp)
    80003e24:	64a2                	ld	s1,8(sp)
    80003e26:	6105                	addi	sp,sp,32
    80003e28:	8082                	ret

0000000080003e2a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e2a:	1141                	addi	sp,sp,-16
    80003e2c:	e422                	sd	s0,8(sp)
    80003e2e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e30:	411c                	lw	a5,0(a0)
    80003e32:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e34:	415c                	lw	a5,4(a0)
    80003e36:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e38:	04451783          	lh	a5,68(a0)
    80003e3c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e40:	04a51783          	lh	a5,74(a0)
    80003e44:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e48:	04c56783          	lwu	a5,76(a0)
    80003e4c:	e99c                	sd	a5,16(a1)
}
    80003e4e:	6422                	ld	s0,8(sp)
    80003e50:	0141                	addi	sp,sp,16
    80003e52:	8082                	ret

0000000080003e54 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e54:	457c                	lw	a5,76(a0)
    80003e56:	0ed7e963          	bltu	a5,a3,80003f48 <readi+0xf4>
{
    80003e5a:	7159                	addi	sp,sp,-112
    80003e5c:	f486                	sd	ra,104(sp)
    80003e5e:	f0a2                	sd	s0,96(sp)
    80003e60:	eca6                	sd	s1,88(sp)
    80003e62:	e8ca                	sd	s2,80(sp)
    80003e64:	e4ce                	sd	s3,72(sp)
    80003e66:	e0d2                	sd	s4,64(sp)
    80003e68:	fc56                	sd	s5,56(sp)
    80003e6a:	f85a                	sd	s6,48(sp)
    80003e6c:	f45e                	sd	s7,40(sp)
    80003e6e:	f062                	sd	s8,32(sp)
    80003e70:	ec66                	sd	s9,24(sp)
    80003e72:	e86a                	sd	s10,16(sp)
    80003e74:	e46e                	sd	s11,8(sp)
    80003e76:	1880                	addi	s0,sp,112
    80003e78:	8b2a                	mv	s6,a0
    80003e7a:	8bae                	mv	s7,a1
    80003e7c:	8a32                	mv	s4,a2
    80003e7e:	84b6                	mv	s1,a3
    80003e80:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e82:	9f35                	addw	a4,a4,a3
    return 0;
    80003e84:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e86:	0ad76063          	bltu	a4,a3,80003f26 <readi+0xd2>
  if(off + n > ip->size)
    80003e8a:	00e7f463          	bgeu	a5,a4,80003e92 <readi+0x3e>
    n = ip->size - off;
    80003e8e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e92:	0a0a8963          	beqz	s5,80003f44 <readi+0xf0>
    80003e96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e98:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e9c:	5c7d                	li	s8,-1
    80003e9e:	a82d                	j	80003ed8 <readi+0x84>
    80003ea0:	020d1d93          	slli	s11,s10,0x20
    80003ea4:	020ddd93          	srli	s11,s11,0x20
    80003ea8:	05890793          	addi	a5,s2,88
    80003eac:	86ee                	mv	a3,s11
    80003eae:	963e                	add	a2,a2,a5
    80003eb0:	85d2                	mv	a1,s4
    80003eb2:	855e                	mv	a0,s7
    80003eb4:	ffffe097          	auipc	ra,0xffffe
    80003eb8:	720080e7          	jalr	1824(ra) # 800025d4 <either_copyout>
    80003ebc:	05850d63          	beq	a0,s8,80003f16 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	5f4080e7          	jalr	1524(ra) # 800034b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eca:	013d09bb          	addw	s3,s10,s3
    80003ece:	009d04bb          	addw	s1,s10,s1
    80003ed2:	9a6e                	add	s4,s4,s11
    80003ed4:	0559f763          	bgeu	s3,s5,80003f22 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ed8:	00a4d59b          	srliw	a1,s1,0xa
    80003edc:	855a                	mv	a0,s6
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	8a2080e7          	jalr	-1886(ra) # 80003780 <bmap>
    80003ee6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eea:	cd85                	beqz	a1,80003f22 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003eec:	000b2503          	lw	a0,0(s6)
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	496080e7          	jalr	1174(ra) # 80003386 <bread>
    80003ef8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003efa:	3ff4f613          	andi	a2,s1,1023
    80003efe:	40cc87bb          	subw	a5,s9,a2
    80003f02:	413a873b          	subw	a4,s5,s3
    80003f06:	8d3e                	mv	s10,a5
    80003f08:	2781                	sext.w	a5,a5
    80003f0a:	0007069b          	sext.w	a3,a4
    80003f0e:	f8f6f9e3          	bgeu	a3,a5,80003ea0 <readi+0x4c>
    80003f12:	8d3a                	mv	s10,a4
    80003f14:	b771                	j	80003ea0 <readi+0x4c>
      brelse(bp);
    80003f16:	854a                	mv	a0,s2
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	59e080e7          	jalr	1438(ra) # 800034b6 <brelse>
      tot = -1;
    80003f20:	59fd                	li	s3,-1
  }
  return tot;
    80003f22:	0009851b          	sext.w	a0,s3
}
    80003f26:	70a6                	ld	ra,104(sp)
    80003f28:	7406                	ld	s0,96(sp)
    80003f2a:	64e6                	ld	s1,88(sp)
    80003f2c:	6946                	ld	s2,80(sp)
    80003f2e:	69a6                	ld	s3,72(sp)
    80003f30:	6a06                	ld	s4,64(sp)
    80003f32:	7ae2                	ld	s5,56(sp)
    80003f34:	7b42                	ld	s6,48(sp)
    80003f36:	7ba2                	ld	s7,40(sp)
    80003f38:	7c02                	ld	s8,32(sp)
    80003f3a:	6ce2                	ld	s9,24(sp)
    80003f3c:	6d42                	ld	s10,16(sp)
    80003f3e:	6da2                	ld	s11,8(sp)
    80003f40:	6165                	addi	sp,sp,112
    80003f42:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f44:	89d6                	mv	s3,s5
    80003f46:	bff1                	j	80003f22 <readi+0xce>
    return 0;
    80003f48:	4501                	li	a0,0
}
    80003f4a:	8082                	ret

0000000080003f4c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f4c:	457c                	lw	a5,76(a0)
    80003f4e:	10d7e863          	bltu	a5,a3,8000405e <writei+0x112>
{
    80003f52:	7159                	addi	sp,sp,-112
    80003f54:	f486                	sd	ra,104(sp)
    80003f56:	f0a2                	sd	s0,96(sp)
    80003f58:	eca6                	sd	s1,88(sp)
    80003f5a:	e8ca                	sd	s2,80(sp)
    80003f5c:	e4ce                	sd	s3,72(sp)
    80003f5e:	e0d2                	sd	s4,64(sp)
    80003f60:	fc56                	sd	s5,56(sp)
    80003f62:	f85a                	sd	s6,48(sp)
    80003f64:	f45e                	sd	s7,40(sp)
    80003f66:	f062                	sd	s8,32(sp)
    80003f68:	ec66                	sd	s9,24(sp)
    80003f6a:	e86a                	sd	s10,16(sp)
    80003f6c:	e46e                	sd	s11,8(sp)
    80003f6e:	1880                	addi	s0,sp,112
    80003f70:	8aaa                	mv	s5,a0
    80003f72:	8bae                	mv	s7,a1
    80003f74:	8a32                	mv	s4,a2
    80003f76:	8936                	mv	s2,a3
    80003f78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f7a:	00e687bb          	addw	a5,a3,a4
    80003f7e:	0ed7e263          	bltu	a5,a3,80004062 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f82:	00043737          	lui	a4,0x43
    80003f86:	0ef76063          	bltu	a4,a5,80004066 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f8a:	0c0b0863          	beqz	s6,8000405a <writei+0x10e>
    80003f8e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f90:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f94:	5c7d                	li	s8,-1
    80003f96:	a091                	j	80003fda <writei+0x8e>
    80003f98:	020d1d93          	slli	s11,s10,0x20
    80003f9c:	020ddd93          	srli	s11,s11,0x20
    80003fa0:	05848793          	addi	a5,s1,88
    80003fa4:	86ee                	mv	a3,s11
    80003fa6:	8652                	mv	a2,s4
    80003fa8:	85de                	mv	a1,s7
    80003faa:	953e                	add	a0,a0,a5
    80003fac:	ffffe097          	auipc	ra,0xffffe
    80003fb0:	67e080e7          	jalr	1662(ra) # 8000262a <either_copyin>
    80003fb4:	07850263          	beq	a0,s8,80004018 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	780080e7          	jalr	1920(ra) # 8000473a <log_write>
    brelse(bp);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	4f2080e7          	jalr	1266(ra) # 800034b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fcc:	013d09bb          	addw	s3,s10,s3
    80003fd0:	012d093b          	addw	s2,s10,s2
    80003fd4:	9a6e                	add	s4,s4,s11
    80003fd6:	0569f663          	bgeu	s3,s6,80004022 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fda:	00a9559b          	srliw	a1,s2,0xa
    80003fde:	8556                	mv	a0,s5
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	7a0080e7          	jalr	1952(ra) # 80003780 <bmap>
    80003fe8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fec:	c99d                	beqz	a1,80004022 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003fee:	000aa503          	lw	a0,0(s5)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	394080e7          	jalr	916(ra) # 80003386 <bread>
    80003ffa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ffc:	3ff97513          	andi	a0,s2,1023
    80004000:	40ac87bb          	subw	a5,s9,a0
    80004004:	413b073b          	subw	a4,s6,s3
    80004008:	8d3e                	mv	s10,a5
    8000400a:	2781                	sext.w	a5,a5
    8000400c:	0007069b          	sext.w	a3,a4
    80004010:	f8f6f4e3          	bgeu	a3,a5,80003f98 <writei+0x4c>
    80004014:	8d3a                	mv	s10,a4
    80004016:	b749                	j	80003f98 <writei+0x4c>
      brelse(bp);
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	49c080e7          	jalr	1180(ra) # 800034b6 <brelse>
  }

  if(off > ip->size)
    80004022:	04caa783          	lw	a5,76(s5)
    80004026:	0127f463          	bgeu	a5,s2,8000402e <writei+0xe2>
    ip->size = off;
    8000402a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000402e:	8556                	mv	a0,s5
    80004030:	00000097          	auipc	ra,0x0
    80004034:	aa6080e7          	jalr	-1370(ra) # 80003ad6 <iupdate>

  return tot;
    80004038:	0009851b          	sext.w	a0,s3
}
    8000403c:	70a6                	ld	ra,104(sp)
    8000403e:	7406                	ld	s0,96(sp)
    80004040:	64e6                	ld	s1,88(sp)
    80004042:	6946                	ld	s2,80(sp)
    80004044:	69a6                	ld	s3,72(sp)
    80004046:	6a06                	ld	s4,64(sp)
    80004048:	7ae2                	ld	s5,56(sp)
    8000404a:	7b42                	ld	s6,48(sp)
    8000404c:	7ba2                	ld	s7,40(sp)
    8000404e:	7c02                	ld	s8,32(sp)
    80004050:	6ce2                	ld	s9,24(sp)
    80004052:	6d42                	ld	s10,16(sp)
    80004054:	6da2                	ld	s11,8(sp)
    80004056:	6165                	addi	sp,sp,112
    80004058:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000405a:	89da                	mv	s3,s6
    8000405c:	bfc9                	j	8000402e <writei+0xe2>
    return -1;
    8000405e:	557d                	li	a0,-1
}
    80004060:	8082                	ret
    return -1;
    80004062:	557d                	li	a0,-1
    80004064:	bfe1                	j	8000403c <writei+0xf0>
    return -1;
    80004066:	557d                	li	a0,-1
    80004068:	bfd1                	j	8000403c <writei+0xf0>

000000008000406a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000406a:	1141                	addi	sp,sp,-16
    8000406c:	e406                	sd	ra,8(sp)
    8000406e:	e022                	sd	s0,0(sp)
    80004070:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004072:	4639                	li	a2,14
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	d2e080e7          	jalr	-722(ra) # 80000da2 <strncmp>
}
    8000407c:	60a2                	ld	ra,8(sp)
    8000407e:	6402                	ld	s0,0(sp)
    80004080:	0141                	addi	sp,sp,16
    80004082:	8082                	ret

0000000080004084 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004084:	7139                	addi	sp,sp,-64
    80004086:	fc06                	sd	ra,56(sp)
    80004088:	f822                	sd	s0,48(sp)
    8000408a:	f426                	sd	s1,40(sp)
    8000408c:	f04a                	sd	s2,32(sp)
    8000408e:	ec4e                	sd	s3,24(sp)
    80004090:	e852                	sd	s4,16(sp)
    80004092:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004094:	04451703          	lh	a4,68(a0)
    80004098:	4785                	li	a5,1
    8000409a:	00f71a63          	bne	a4,a5,800040ae <dirlookup+0x2a>
    8000409e:	892a                	mv	s2,a0
    800040a0:	89ae                	mv	s3,a1
    800040a2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a4:	457c                	lw	a5,76(a0)
    800040a6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040a8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040aa:	e79d                	bnez	a5,800040d8 <dirlookup+0x54>
    800040ac:	a8a5                	j	80004124 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040ae:	00004517          	auipc	a0,0x4
    800040b2:	56250513          	addi	a0,a0,1378 # 80008610 <syscalls+0x1c0>
    800040b6:	ffffc097          	auipc	ra,0xffffc
    800040ba:	488080e7          	jalr	1160(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040be:	00004517          	auipc	a0,0x4
    800040c2:	56a50513          	addi	a0,a0,1386 # 80008628 <syscalls+0x1d8>
    800040c6:	ffffc097          	auipc	ra,0xffffc
    800040ca:	478080e7          	jalr	1144(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ce:	24c1                	addiw	s1,s1,16
    800040d0:	04c92783          	lw	a5,76(s2)
    800040d4:	04f4f763          	bgeu	s1,a5,80004122 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d8:	4741                	li	a4,16
    800040da:	86a6                	mv	a3,s1
    800040dc:	fc040613          	addi	a2,s0,-64
    800040e0:	4581                	li	a1,0
    800040e2:	854a                	mv	a0,s2
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	d70080e7          	jalr	-656(ra) # 80003e54 <readi>
    800040ec:	47c1                	li	a5,16
    800040ee:	fcf518e3          	bne	a0,a5,800040be <dirlookup+0x3a>
    if(de.inum == 0)
    800040f2:	fc045783          	lhu	a5,-64(s0)
    800040f6:	dfe1                	beqz	a5,800040ce <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040f8:	fc240593          	addi	a1,s0,-62
    800040fc:	854e                	mv	a0,s3
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	f6c080e7          	jalr	-148(ra) # 8000406a <namecmp>
    80004106:	f561                	bnez	a0,800040ce <dirlookup+0x4a>
      if(poff)
    80004108:	000a0463          	beqz	s4,80004110 <dirlookup+0x8c>
        *poff = off;
    8000410c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004110:	fc045583          	lhu	a1,-64(s0)
    80004114:	00092503          	lw	a0,0(s2)
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	750080e7          	jalr	1872(ra) # 80003868 <iget>
    80004120:	a011                	j	80004124 <dirlookup+0xa0>
  return 0;
    80004122:	4501                	li	a0,0
}
    80004124:	70e2                	ld	ra,56(sp)
    80004126:	7442                	ld	s0,48(sp)
    80004128:	74a2                	ld	s1,40(sp)
    8000412a:	7902                	ld	s2,32(sp)
    8000412c:	69e2                	ld	s3,24(sp)
    8000412e:	6a42                	ld	s4,16(sp)
    80004130:	6121                	addi	sp,sp,64
    80004132:	8082                	ret

0000000080004134 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004134:	711d                	addi	sp,sp,-96
    80004136:	ec86                	sd	ra,88(sp)
    80004138:	e8a2                	sd	s0,80(sp)
    8000413a:	e4a6                	sd	s1,72(sp)
    8000413c:	e0ca                	sd	s2,64(sp)
    8000413e:	fc4e                	sd	s3,56(sp)
    80004140:	f852                	sd	s4,48(sp)
    80004142:	f456                	sd	s5,40(sp)
    80004144:	f05a                	sd	s6,32(sp)
    80004146:	ec5e                	sd	s7,24(sp)
    80004148:	e862                	sd	s8,16(sp)
    8000414a:	e466                	sd	s9,8(sp)
    8000414c:	1080                	addi	s0,sp,96
    8000414e:	84aa                	mv	s1,a0
    80004150:	8aae                	mv	s5,a1
    80004152:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004154:	00054703          	lbu	a4,0(a0)
    80004158:	02f00793          	li	a5,47
    8000415c:	02f70363          	beq	a4,a5,80004182 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004160:	ffffe097          	auipc	ra,0xffffe
    80004164:	8d6080e7          	jalr	-1834(ra) # 80001a36 <myproc>
    80004168:	15853503          	ld	a0,344(a0)
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	9f6080e7          	jalr	-1546(ra) # 80003b62 <idup>
    80004174:	89aa                	mv	s3,a0
  while(*path == '/')
    80004176:	02f00913          	li	s2,47
  len = path - s;
    8000417a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000417c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000417e:	4b85                	li	s7,1
    80004180:	a865                	j	80004238 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004182:	4585                	li	a1,1
    80004184:	4505                	li	a0,1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	6e2080e7          	jalr	1762(ra) # 80003868 <iget>
    8000418e:	89aa                	mv	s3,a0
    80004190:	b7dd                	j	80004176 <namex+0x42>
      iunlockput(ip);
    80004192:	854e                	mv	a0,s3
    80004194:	00000097          	auipc	ra,0x0
    80004198:	c6e080e7          	jalr	-914(ra) # 80003e02 <iunlockput>
      return 0;
    8000419c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000419e:	854e                	mv	a0,s3
    800041a0:	60e6                	ld	ra,88(sp)
    800041a2:	6446                	ld	s0,80(sp)
    800041a4:	64a6                	ld	s1,72(sp)
    800041a6:	6906                	ld	s2,64(sp)
    800041a8:	79e2                	ld	s3,56(sp)
    800041aa:	7a42                	ld	s4,48(sp)
    800041ac:	7aa2                	ld	s5,40(sp)
    800041ae:	7b02                	ld	s6,32(sp)
    800041b0:	6be2                	ld	s7,24(sp)
    800041b2:	6c42                	ld	s8,16(sp)
    800041b4:	6ca2                	ld	s9,8(sp)
    800041b6:	6125                	addi	sp,sp,96
    800041b8:	8082                	ret
      iunlock(ip);
    800041ba:	854e                	mv	a0,s3
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	aa6080e7          	jalr	-1370(ra) # 80003c62 <iunlock>
      return ip;
    800041c4:	bfe9                	j	8000419e <namex+0x6a>
      iunlockput(ip);
    800041c6:	854e                	mv	a0,s3
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	c3a080e7          	jalr	-966(ra) # 80003e02 <iunlockput>
      return 0;
    800041d0:	89e6                	mv	s3,s9
    800041d2:	b7f1                	j	8000419e <namex+0x6a>
  len = path - s;
    800041d4:	40b48633          	sub	a2,s1,a1
    800041d8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041dc:	099c5463          	bge	s8,s9,80004264 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041e0:	4639                	li	a2,14
    800041e2:	8552                	mv	a0,s4
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	b4a080e7          	jalr	-1206(ra) # 80000d2e <memmove>
  while(*path == '/')
    800041ec:	0004c783          	lbu	a5,0(s1)
    800041f0:	01279763          	bne	a5,s2,800041fe <namex+0xca>
    path++;
    800041f4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041f6:	0004c783          	lbu	a5,0(s1)
    800041fa:	ff278de3          	beq	a5,s2,800041f4 <namex+0xc0>
    ilock(ip);
    800041fe:	854e                	mv	a0,s3
    80004200:	00000097          	auipc	ra,0x0
    80004204:	9a0080e7          	jalr	-1632(ra) # 80003ba0 <ilock>
    if(ip->type != T_DIR){
    80004208:	04499783          	lh	a5,68(s3)
    8000420c:	f97793e3          	bne	a5,s7,80004192 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004210:	000a8563          	beqz	s5,8000421a <namex+0xe6>
    80004214:	0004c783          	lbu	a5,0(s1)
    80004218:	d3cd                	beqz	a5,800041ba <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000421a:	865a                	mv	a2,s6
    8000421c:	85d2                	mv	a1,s4
    8000421e:	854e                	mv	a0,s3
    80004220:	00000097          	auipc	ra,0x0
    80004224:	e64080e7          	jalr	-412(ra) # 80004084 <dirlookup>
    80004228:	8caa                	mv	s9,a0
    8000422a:	dd51                	beqz	a0,800041c6 <namex+0x92>
    iunlockput(ip);
    8000422c:	854e                	mv	a0,s3
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	bd4080e7          	jalr	-1068(ra) # 80003e02 <iunlockput>
    ip = next;
    80004236:	89e6                	mv	s3,s9
  while(*path == '/')
    80004238:	0004c783          	lbu	a5,0(s1)
    8000423c:	05279763          	bne	a5,s2,8000428a <namex+0x156>
    path++;
    80004240:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004242:	0004c783          	lbu	a5,0(s1)
    80004246:	ff278de3          	beq	a5,s2,80004240 <namex+0x10c>
  if(*path == 0)
    8000424a:	c79d                	beqz	a5,80004278 <namex+0x144>
    path++;
    8000424c:	85a6                	mv	a1,s1
  len = path - s;
    8000424e:	8cda                	mv	s9,s6
    80004250:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004252:	01278963          	beq	a5,s2,80004264 <namex+0x130>
    80004256:	dfbd                	beqz	a5,800041d4 <namex+0xa0>
    path++;
    80004258:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000425a:	0004c783          	lbu	a5,0(s1)
    8000425e:	ff279ce3          	bne	a5,s2,80004256 <namex+0x122>
    80004262:	bf8d                	j	800041d4 <namex+0xa0>
    memmove(name, s, len);
    80004264:	2601                	sext.w	a2,a2
    80004266:	8552                	mv	a0,s4
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	ac6080e7          	jalr	-1338(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004270:	9cd2                	add	s9,s9,s4
    80004272:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004276:	bf9d                	j	800041ec <namex+0xb8>
  if(nameiparent){
    80004278:	f20a83e3          	beqz	s5,8000419e <namex+0x6a>
    iput(ip);
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	adc080e7          	jalr	-1316(ra) # 80003d5a <iput>
    return 0;
    80004286:	4981                	li	s3,0
    80004288:	bf19                	j	8000419e <namex+0x6a>
  if(*path == 0)
    8000428a:	d7fd                	beqz	a5,80004278 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	85a6                	mv	a1,s1
    80004292:	b7d1                	j	80004256 <namex+0x122>

0000000080004294 <dirlink>:
{
    80004294:	7139                	addi	sp,sp,-64
    80004296:	fc06                	sd	ra,56(sp)
    80004298:	f822                	sd	s0,48(sp)
    8000429a:	f426                	sd	s1,40(sp)
    8000429c:	f04a                	sd	s2,32(sp)
    8000429e:	ec4e                	sd	s3,24(sp)
    800042a0:	e852                	sd	s4,16(sp)
    800042a2:	0080                	addi	s0,sp,64
    800042a4:	892a                	mv	s2,a0
    800042a6:	8a2e                	mv	s4,a1
    800042a8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042aa:	4601                	li	a2,0
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	dd8080e7          	jalr	-552(ra) # 80004084 <dirlookup>
    800042b4:	e93d                	bnez	a0,8000432a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b6:	04c92483          	lw	s1,76(s2)
    800042ba:	c49d                	beqz	s1,800042e8 <dirlink+0x54>
    800042bc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042be:	4741                	li	a4,16
    800042c0:	86a6                	mv	a3,s1
    800042c2:	fc040613          	addi	a2,s0,-64
    800042c6:	4581                	li	a1,0
    800042c8:	854a                	mv	a0,s2
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	b8a080e7          	jalr	-1142(ra) # 80003e54 <readi>
    800042d2:	47c1                	li	a5,16
    800042d4:	06f51163          	bne	a0,a5,80004336 <dirlink+0xa2>
    if(de.inum == 0)
    800042d8:	fc045783          	lhu	a5,-64(s0)
    800042dc:	c791                	beqz	a5,800042e8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042de:	24c1                	addiw	s1,s1,16
    800042e0:	04c92783          	lw	a5,76(s2)
    800042e4:	fcf4ede3          	bltu	s1,a5,800042be <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042e8:	4639                	li	a2,14
    800042ea:	85d2                	mv	a1,s4
    800042ec:	fc240513          	addi	a0,s0,-62
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	aee080e7          	jalr	-1298(ra) # 80000dde <strncpy>
  de.inum = inum;
    800042f8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042fc:	4741                	li	a4,16
    800042fe:	86a6                	mv	a3,s1
    80004300:	fc040613          	addi	a2,s0,-64
    80004304:	4581                	li	a1,0
    80004306:	854a                	mv	a0,s2
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	c44080e7          	jalr	-956(ra) # 80003f4c <writei>
    80004310:	1541                	addi	a0,a0,-16
    80004312:	00a03533          	snez	a0,a0
    80004316:	40a00533          	neg	a0,a0
}
    8000431a:	70e2                	ld	ra,56(sp)
    8000431c:	7442                	ld	s0,48(sp)
    8000431e:	74a2                	ld	s1,40(sp)
    80004320:	7902                	ld	s2,32(sp)
    80004322:	69e2                	ld	s3,24(sp)
    80004324:	6a42                	ld	s4,16(sp)
    80004326:	6121                	addi	sp,sp,64
    80004328:	8082                	ret
    iput(ip);
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	a30080e7          	jalr	-1488(ra) # 80003d5a <iput>
    return -1;
    80004332:	557d                	li	a0,-1
    80004334:	b7dd                	j	8000431a <dirlink+0x86>
      panic("dirlink read");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	30250513          	addi	a0,a0,770 # 80008638 <syscalls+0x1e8>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080004346 <namei>:

struct inode*
namei(char *path)
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000434e:	fe040613          	addi	a2,s0,-32
    80004352:	4581                	li	a1,0
    80004354:	00000097          	auipc	ra,0x0
    80004358:	de0080e7          	jalr	-544(ra) # 80004134 <namex>
}
    8000435c:	60e2                	ld	ra,24(sp)
    8000435e:	6442                	ld	s0,16(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004364:	1141                	addi	sp,sp,-16
    80004366:	e406                	sd	ra,8(sp)
    80004368:	e022                	sd	s0,0(sp)
    8000436a:	0800                	addi	s0,sp,16
    8000436c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000436e:	4585                	li	a1,1
    80004370:	00000097          	auipc	ra,0x0
    80004374:	dc4080e7          	jalr	-572(ra) # 80004134 <namex>
}
    80004378:	60a2                	ld	ra,8(sp)
    8000437a:	6402                	ld	s0,0(sp)
    8000437c:	0141                	addi	sp,sp,16
    8000437e:	8082                	ret

0000000080004380 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000438c:	00021917          	auipc	s2,0x21
    80004390:	df490913          	addi	s2,s2,-524 # 80025180 <log>
    80004394:	01892583          	lw	a1,24(s2)
    80004398:	02892503          	lw	a0,40(s2)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	fea080e7          	jalr	-22(ra) # 80003386 <bread>
    800043a4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043a6:	02c92683          	lw	a3,44(s2)
    800043aa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	02d05763          	blez	a3,800043da <write_head+0x5a>
    800043b0:	00021797          	auipc	a5,0x21
    800043b4:	e0078793          	addi	a5,a5,-512 # 800251b0 <log+0x30>
    800043b8:	05c50713          	addi	a4,a0,92
    800043bc:	36fd                	addiw	a3,a3,-1
    800043be:	1682                	slli	a3,a3,0x20
    800043c0:	9281                	srli	a3,a3,0x20
    800043c2:	068a                	slli	a3,a3,0x2
    800043c4:	00021617          	auipc	a2,0x21
    800043c8:	df060613          	addi	a2,a2,-528 # 800251b4 <log+0x34>
    800043cc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043ce:	4390                	lw	a2,0(a5)
    800043d0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	0791                	addi	a5,a5,4
    800043d4:	0711                	addi	a4,a4,4
    800043d6:	fed79ce3          	bne	a5,a3,800043ce <write_head+0x4e>
  }
  bwrite(buf);
    800043da:	8526                	mv	a0,s1
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	09c080e7          	jalr	156(ra) # 80003478 <bwrite>
  brelse(buf);
    800043e4:	8526                	mv	a0,s1
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	0d0080e7          	jalr	208(ra) # 800034b6 <brelse>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fa:	00021797          	auipc	a5,0x21
    800043fe:	db27a783          	lw	a5,-590(a5) # 800251ac <log+0x2c>
    80004402:	0af05d63          	blez	a5,800044bc <install_trans+0xc2>
{
    80004406:	7139                	addi	sp,sp,-64
    80004408:	fc06                	sd	ra,56(sp)
    8000440a:	f822                	sd	s0,48(sp)
    8000440c:	f426                	sd	s1,40(sp)
    8000440e:	f04a                	sd	s2,32(sp)
    80004410:	ec4e                	sd	s3,24(sp)
    80004412:	e852                	sd	s4,16(sp)
    80004414:	e456                	sd	s5,8(sp)
    80004416:	e05a                	sd	s6,0(sp)
    80004418:	0080                	addi	s0,sp,64
    8000441a:	8b2a                	mv	s6,a0
    8000441c:	00021a97          	auipc	s5,0x21
    80004420:	d94a8a93          	addi	s5,s5,-620 # 800251b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004424:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004426:	00021997          	auipc	s3,0x21
    8000442a:	d5a98993          	addi	s3,s3,-678 # 80025180 <log>
    8000442e:	a00d                	j	80004450 <install_trans+0x56>
    brelse(lbuf);
    80004430:	854a                	mv	a0,s2
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	084080e7          	jalr	132(ra) # 800034b6 <brelse>
    brelse(dbuf);
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	07a080e7          	jalr	122(ra) # 800034b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004444:	2a05                	addiw	s4,s4,1
    80004446:	0a91                	addi	s5,s5,4
    80004448:	02c9a783          	lw	a5,44(s3)
    8000444c:	04fa5e63          	bge	s4,a5,800044a8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004450:	0189a583          	lw	a1,24(s3)
    80004454:	014585bb          	addw	a1,a1,s4
    80004458:	2585                	addiw	a1,a1,1
    8000445a:	0289a503          	lw	a0,40(s3)
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	f28080e7          	jalr	-216(ra) # 80003386 <bread>
    80004466:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004468:	000aa583          	lw	a1,0(s5)
    8000446c:	0289a503          	lw	a0,40(s3)
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	f16080e7          	jalr	-234(ra) # 80003386 <bread>
    80004478:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000447a:	40000613          	li	a2,1024
    8000447e:	05890593          	addi	a1,s2,88
    80004482:	05850513          	addi	a0,a0,88
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	8a8080e7          	jalr	-1880(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	fe8080e7          	jalr	-24(ra) # 80003478 <bwrite>
    if(recovering == 0)
    80004498:	f80b1ce3          	bnez	s6,80004430 <install_trans+0x36>
      bunpin(dbuf);
    8000449c:	8526                	mv	a0,s1
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	0f2080e7          	jalr	242(ra) # 80003590 <bunpin>
    800044a6:	b769                	j	80004430 <install_trans+0x36>
}
    800044a8:	70e2                	ld	ra,56(sp)
    800044aa:	7442                	ld	s0,48(sp)
    800044ac:	74a2                	ld	s1,40(sp)
    800044ae:	7902                	ld	s2,32(sp)
    800044b0:	69e2                	ld	s3,24(sp)
    800044b2:	6a42                	ld	s4,16(sp)
    800044b4:	6aa2                	ld	s5,8(sp)
    800044b6:	6b02                	ld	s6,0(sp)
    800044b8:	6121                	addi	sp,sp,64
    800044ba:	8082                	ret
    800044bc:	8082                	ret

00000000800044be <initlog>:
{
    800044be:	7179                	addi	sp,sp,-48
    800044c0:	f406                	sd	ra,40(sp)
    800044c2:	f022                	sd	s0,32(sp)
    800044c4:	ec26                	sd	s1,24(sp)
    800044c6:	e84a                	sd	s2,16(sp)
    800044c8:	e44e                	sd	s3,8(sp)
    800044ca:	1800                	addi	s0,sp,48
    800044cc:	892a                	mv	s2,a0
    800044ce:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d0:	00021497          	auipc	s1,0x21
    800044d4:	cb048493          	addi	s1,s1,-848 # 80025180 <log>
    800044d8:	00004597          	auipc	a1,0x4
    800044dc:	17058593          	addi	a1,a1,368 # 80008648 <syscalls+0x1f8>
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	664080e7          	jalr	1636(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800044ea:	0149a583          	lw	a1,20(s3)
    800044ee:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044f0:	0109a783          	lw	a5,16(s3)
    800044f4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044f6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044fa:	854a                	mv	a0,s2
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	e8a080e7          	jalr	-374(ra) # 80003386 <bread>
  log.lh.n = lh->n;
    80004504:	4d34                	lw	a3,88(a0)
    80004506:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004508:	02d05563          	blez	a3,80004532 <initlog+0x74>
    8000450c:	05c50793          	addi	a5,a0,92
    80004510:	00021717          	auipc	a4,0x21
    80004514:	ca070713          	addi	a4,a4,-864 # 800251b0 <log+0x30>
    80004518:	36fd                	addiw	a3,a3,-1
    8000451a:	1682                	slli	a3,a3,0x20
    8000451c:	9281                	srli	a3,a3,0x20
    8000451e:	068a                	slli	a3,a3,0x2
    80004520:	06050613          	addi	a2,a0,96
    80004524:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004526:	4390                	lw	a2,0(a5)
    80004528:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	0791                	addi	a5,a5,4
    8000452c:	0711                	addi	a4,a4,4
    8000452e:	fed79ce3          	bne	a5,a3,80004526 <initlog+0x68>
  brelse(buf);
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	f84080e7          	jalr	-124(ra) # 800034b6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000453a:	4505                	li	a0,1
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	ebe080e7          	jalr	-322(ra) # 800043fa <install_trans>
  log.lh.n = 0;
    80004544:	00021797          	auipc	a5,0x21
    80004548:	c607a423          	sw	zero,-920(a5) # 800251ac <log+0x2c>
  write_head(); // clear the log
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	e34080e7          	jalr	-460(ra) # 80004380 <write_head>
}
    80004554:	70a2                	ld	ra,40(sp)
    80004556:	7402                	ld	s0,32(sp)
    80004558:	64e2                	ld	s1,24(sp)
    8000455a:	6942                	ld	s2,16(sp)
    8000455c:	69a2                	ld	s3,8(sp)
    8000455e:	6145                	addi	sp,sp,48
    80004560:	8082                	ret

0000000080004562 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000456e:	00021517          	auipc	a0,0x21
    80004572:	c1250513          	addi	a0,a0,-1006 # 80025180 <log>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	660080e7          	jalr	1632(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000457e:	00021497          	auipc	s1,0x21
    80004582:	c0248493          	addi	s1,s1,-1022 # 80025180 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004586:	4979                	li	s2,30
    80004588:	a039                	j	80004596 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000458a:	85a6                	mv	a1,s1
    8000458c:	8526                	mv	a0,s1
    8000458e:	ffffe097          	auipc	ra,0xffffe
    80004592:	c32080e7          	jalr	-974(ra) # 800021c0 <sleep>
    if(log.committing){
    80004596:	50dc                	lw	a5,36(s1)
    80004598:	fbed                	bnez	a5,8000458a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000459a:	509c                	lw	a5,32(s1)
    8000459c:	0017871b          	addiw	a4,a5,1
    800045a0:	0007069b          	sext.w	a3,a4
    800045a4:	0027179b          	slliw	a5,a4,0x2
    800045a8:	9fb9                	addw	a5,a5,a4
    800045aa:	0017979b          	slliw	a5,a5,0x1
    800045ae:	54d8                	lw	a4,44(s1)
    800045b0:	9fb9                	addw	a5,a5,a4
    800045b2:	00f95963          	bge	s2,a5,800045c4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045b6:	85a6                	mv	a1,s1
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffe097          	auipc	ra,0xffffe
    800045be:	c06080e7          	jalr	-1018(ra) # 800021c0 <sleep>
    800045c2:	bfd1                	j	80004596 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045c4:	00021517          	auipc	a0,0x21
    800045c8:	bbc50513          	addi	a0,a0,-1092 # 80025180 <log>
    800045cc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
      break;
    }
  }
}
    800045d6:	60e2                	ld	ra,24(sp)
    800045d8:	6442                	ld	s0,16(sp)
    800045da:	64a2                	ld	s1,8(sp)
    800045dc:	6902                	ld	s2,0(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret

00000000800045e2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045e2:	7139                	addi	sp,sp,-64
    800045e4:	fc06                	sd	ra,56(sp)
    800045e6:	f822                	sd	s0,48(sp)
    800045e8:	f426                	sd	s1,40(sp)
    800045ea:	f04a                	sd	s2,32(sp)
    800045ec:	ec4e                	sd	s3,24(sp)
    800045ee:	e852                	sd	s4,16(sp)
    800045f0:	e456                	sd	s5,8(sp)
    800045f2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045f4:	00021497          	auipc	s1,0x21
    800045f8:	b8c48493          	addi	s1,s1,-1140 # 80025180 <log>
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5d8080e7          	jalr	1496(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004606:	509c                	lw	a5,32(s1)
    80004608:	37fd                	addiw	a5,a5,-1
    8000460a:	0007891b          	sext.w	s2,a5
    8000460e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004610:	50dc                	lw	a5,36(s1)
    80004612:	e7b9                	bnez	a5,80004660 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004614:	04091e63          	bnez	s2,80004670 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004618:	00021497          	auipc	s1,0x21
    8000461c:	b6848493          	addi	s1,s1,-1176 # 80025180 <log>
    80004620:	4785                	li	a5,1
    80004622:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004624:	8526                	mv	a0,s1
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	664080e7          	jalr	1636(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000462e:	54dc                	lw	a5,44(s1)
    80004630:	06f04763          	bgtz	a5,8000469e <end_op+0xbc>
    acquire(&log.lock);
    80004634:	00021497          	auipc	s1,0x21
    80004638:	b4c48493          	addi	s1,s1,-1204 # 80025180 <log>
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	598080e7          	jalr	1432(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004646:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000464a:	8526                	mv	a0,s1
    8000464c:	ffffe097          	auipc	ra,0xffffe
    80004650:	bd8080e7          	jalr	-1064(ra) # 80002224 <wakeup>
    release(&log.lock);
    80004654:	8526                	mv	a0,s1
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
}
    8000465e:	a03d                	j	8000468c <end_op+0xaa>
    panic("log.committing");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	ff050513          	addi	a0,a0,-16 # 80008650 <syscalls+0x200>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
    wakeup(&log);
    80004670:	00021497          	auipc	s1,0x21
    80004674:	b1048493          	addi	s1,s1,-1264 # 80025180 <log>
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffe097          	auipc	ra,0xffffe
    8000467e:	baa080e7          	jalr	-1110(ra) # 80002224 <wakeup>
  release(&log.lock);
    80004682:	8526                	mv	a0,s1
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	606080e7          	jalr	1542(ra) # 80000c8a <release>
}
    8000468c:	70e2                	ld	ra,56(sp)
    8000468e:	7442                	ld	s0,48(sp)
    80004690:	74a2                	ld	s1,40(sp)
    80004692:	7902                	ld	s2,32(sp)
    80004694:	69e2                	ld	s3,24(sp)
    80004696:	6a42                	ld	s4,16(sp)
    80004698:	6aa2                	ld	s5,8(sp)
    8000469a:	6121                	addi	sp,sp,64
    8000469c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469e:	00021a97          	auipc	s5,0x21
    800046a2:	b12a8a93          	addi	s5,s5,-1262 # 800251b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046a6:	00021a17          	auipc	s4,0x21
    800046aa:	adaa0a13          	addi	s4,s4,-1318 # 80025180 <log>
    800046ae:	018a2583          	lw	a1,24(s4)
    800046b2:	012585bb          	addw	a1,a1,s2
    800046b6:	2585                	addiw	a1,a1,1
    800046b8:	028a2503          	lw	a0,40(s4)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	cca080e7          	jalr	-822(ra) # 80003386 <bread>
    800046c4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046c6:	000aa583          	lw	a1,0(s5)
    800046ca:	028a2503          	lw	a0,40(s4)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	cb8080e7          	jalr	-840(ra) # 80003386 <bread>
    800046d6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046d8:	40000613          	li	a2,1024
    800046dc:	05850593          	addi	a1,a0,88
    800046e0:	05848513          	addi	a0,s1,88
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	64a080e7          	jalr	1610(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800046ec:	8526                	mv	a0,s1
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	d8a080e7          	jalr	-630(ra) # 80003478 <bwrite>
    brelse(from);
    800046f6:	854e                	mv	a0,s3
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	dbe080e7          	jalr	-578(ra) # 800034b6 <brelse>
    brelse(to);
    80004700:	8526                	mv	a0,s1
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	db4080e7          	jalr	-588(ra) # 800034b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000470a:	2905                	addiw	s2,s2,1
    8000470c:	0a91                	addi	s5,s5,4
    8000470e:	02ca2783          	lw	a5,44(s4)
    80004712:	f8f94ee3          	blt	s2,a5,800046ae <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	c6a080e7          	jalr	-918(ra) # 80004380 <write_head>
    install_trans(0); // Now install writes to home locations
    8000471e:	4501                	li	a0,0
    80004720:	00000097          	auipc	ra,0x0
    80004724:	cda080e7          	jalr	-806(ra) # 800043fa <install_trans>
    log.lh.n = 0;
    80004728:	00021797          	auipc	a5,0x21
    8000472c:	a807a223          	sw	zero,-1404(a5) # 800251ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004730:	00000097          	auipc	ra,0x0
    80004734:	c50080e7          	jalr	-944(ra) # 80004380 <write_head>
    80004738:	bdf5                	j	80004634 <end_op+0x52>

000000008000473a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	e04a                	sd	s2,0(sp)
    80004744:	1000                	addi	s0,sp,32
    80004746:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004748:	00021917          	auipc	s2,0x21
    8000474c:	a3890913          	addi	s2,s2,-1480 # 80025180 <log>
    80004750:	854a                	mv	a0,s2
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	484080e7          	jalr	1156(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000475a:	02c92603          	lw	a2,44(s2)
    8000475e:	47f5                	li	a5,29
    80004760:	06c7c563          	blt	a5,a2,800047ca <log_write+0x90>
    80004764:	00021797          	auipc	a5,0x21
    80004768:	a387a783          	lw	a5,-1480(a5) # 8002519c <log+0x1c>
    8000476c:	37fd                	addiw	a5,a5,-1
    8000476e:	04f65e63          	bge	a2,a5,800047ca <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004772:	00021797          	auipc	a5,0x21
    80004776:	a2e7a783          	lw	a5,-1490(a5) # 800251a0 <log+0x20>
    8000477a:	06f05063          	blez	a5,800047da <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000477e:	4781                	li	a5,0
    80004780:	06c05563          	blez	a2,800047ea <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004784:	44cc                	lw	a1,12(s1)
    80004786:	00021717          	auipc	a4,0x21
    8000478a:	a2a70713          	addi	a4,a4,-1494 # 800251b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000478e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004790:	4314                	lw	a3,0(a4)
    80004792:	04b68c63          	beq	a3,a1,800047ea <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004796:	2785                	addiw	a5,a5,1
    80004798:	0711                	addi	a4,a4,4
    8000479a:	fef61be3          	bne	a2,a5,80004790 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000479e:	0621                	addi	a2,a2,8
    800047a0:	060a                	slli	a2,a2,0x2
    800047a2:	00021797          	auipc	a5,0x21
    800047a6:	9de78793          	addi	a5,a5,-1570 # 80025180 <log>
    800047aa:	963e                	add	a2,a2,a5
    800047ac:	44dc                	lw	a5,12(s1)
    800047ae:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047b0:	8526                	mv	a0,s1
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	da2080e7          	jalr	-606(ra) # 80003554 <bpin>
    log.lh.n++;
    800047ba:	00021717          	auipc	a4,0x21
    800047be:	9c670713          	addi	a4,a4,-1594 # 80025180 <log>
    800047c2:	575c                	lw	a5,44(a4)
    800047c4:	2785                	addiw	a5,a5,1
    800047c6:	d75c                	sw	a5,44(a4)
    800047c8:	a835                	j	80004804 <log_write+0xca>
    panic("too big a transaction");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	e9650513          	addi	a0,a0,-362 # 80008660 <syscalls+0x210>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	e9e50513          	addi	a0,a0,-354 # 80008678 <syscalls+0x228>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047ea:	00878713          	addi	a4,a5,8
    800047ee:	00271693          	slli	a3,a4,0x2
    800047f2:	00021717          	auipc	a4,0x21
    800047f6:	98e70713          	addi	a4,a4,-1650 # 80025180 <log>
    800047fa:	9736                	add	a4,a4,a3
    800047fc:	44d4                	lw	a3,12(s1)
    800047fe:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004800:	faf608e3          	beq	a2,a5,800047b0 <log_write+0x76>
  }
  release(&log.lock);
    80004804:	00021517          	auipc	a0,0x21
    80004808:	97c50513          	addi	a0,a0,-1668 # 80025180 <log>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	47e080e7          	jalr	1150(ra) # 80000c8a <release>
}
    80004814:	60e2                	ld	ra,24(sp)
    80004816:	6442                	ld	s0,16(sp)
    80004818:	64a2                	ld	s1,8(sp)
    8000481a:	6902                	ld	s2,0(sp)
    8000481c:	6105                	addi	sp,sp,32
    8000481e:	8082                	ret

0000000080004820 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004820:	1101                	addi	sp,sp,-32
    80004822:	ec06                	sd	ra,24(sp)
    80004824:	e822                	sd	s0,16(sp)
    80004826:	e426                	sd	s1,8(sp)
    80004828:	e04a                	sd	s2,0(sp)
    8000482a:	1000                	addi	s0,sp,32
    8000482c:	84aa                	mv	s1,a0
    8000482e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004830:	00004597          	auipc	a1,0x4
    80004834:	e6858593          	addi	a1,a1,-408 # 80008698 <syscalls+0x248>
    80004838:	0521                	addi	a0,a0,8
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	30c080e7          	jalr	780(ra) # 80000b46 <initlock>
  lk->name = name;
    80004842:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004846:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000484a:	0204a423          	sw	zero,40(s1)
}
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6902                	ld	s2,0(sp)
    80004856:	6105                	addi	sp,sp,32
    80004858:	8082                	ret

000000008000485a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000485a:	1101                	addi	sp,sp,-32
    8000485c:	ec06                	sd	ra,24(sp)
    8000485e:	e822                	sd	s0,16(sp)
    80004860:	e426                	sd	s1,8(sp)
    80004862:	e04a                	sd	s2,0(sp)
    80004864:	1000                	addi	s0,sp,32
    80004866:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004868:	00850913          	addi	s2,a0,8
    8000486c:	854a                	mv	a0,s2
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	368080e7          	jalr	872(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004876:	409c                	lw	a5,0(s1)
    80004878:	cb89                	beqz	a5,8000488a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000487a:	85ca                	mv	a1,s2
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffe097          	auipc	ra,0xffffe
    80004882:	942080e7          	jalr	-1726(ra) # 800021c0 <sleep>
  while (lk->locked) {
    80004886:	409c                	lw	a5,0(s1)
    80004888:	fbed                	bnez	a5,8000487a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000488a:	4785                	li	a5,1
    8000488c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000488e:	ffffd097          	auipc	ra,0xffffd
    80004892:	1a8080e7          	jalr	424(ra) # 80001a36 <myproc>
    80004896:	591c                	lw	a5,48(a0)
    80004898:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000489a:	854a                	mv	a0,s2
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	3ee080e7          	jalr	1006(ra) # 80000c8a <release>
}
    800048a4:	60e2                	ld	ra,24(sp)
    800048a6:	6442                	ld	s0,16(sp)
    800048a8:	64a2                	ld	s1,8(sp)
    800048aa:	6902                	ld	s2,0(sp)
    800048ac:	6105                	addi	sp,sp,32
    800048ae:	8082                	ret

00000000800048b0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048b0:	1101                	addi	sp,sp,-32
    800048b2:	ec06                	sd	ra,24(sp)
    800048b4:	e822                	sd	s0,16(sp)
    800048b6:	e426                	sd	s1,8(sp)
    800048b8:	e04a                	sd	s2,0(sp)
    800048ba:	1000                	addi	s0,sp,32
    800048bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048be:	00850913          	addi	s2,a0,8
    800048c2:	854a                	mv	a0,s2
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	312080e7          	jalr	786(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800048cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffe097          	auipc	ra,0xffffe
    800048da:	94e080e7          	jalr	-1714(ra) # 80002224 <wakeup>
  release(&lk->lk);
    800048de:	854a                	mv	a0,s2
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	3aa080e7          	jalr	938(ra) # 80000c8a <release>
}
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6902                	ld	s2,0(sp)
    800048f0:	6105                	addi	sp,sp,32
    800048f2:	8082                	ret

00000000800048f4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048f4:	7179                	addi	sp,sp,-48
    800048f6:	f406                	sd	ra,40(sp)
    800048f8:	f022                	sd	s0,32(sp)
    800048fa:	ec26                	sd	s1,24(sp)
    800048fc:	e84a                	sd	s2,16(sp)
    800048fe:	e44e                	sd	s3,8(sp)
    80004900:	1800                	addi	s0,sp,48
    80004902:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004904:	00850913          	addi	s2,a0,8
    80004908:	854a                	mv	a0,s2
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	2cc080e7          	jalr	716(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004912:	409c                	lw	a5,0(s1)
    80004914:	ef99                	bnez	a5,80004932 <holdingsleep+0x3e>
    80004916:	4481                	li	s1,0
  release(&lk->lk);
    80004918:	854a                	mv	a0,s2
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	370080e7          	jalr	880(ra) # 80000c8a <release>
  return r;
}
    80004922:	8526                	mv	a0,s1
    80004924:	70a2                	ld	ra,40(sp)
    80004926:	7402                	ld	s0,32(sp)
    80004928:	64e2                	ld	s1,24(sp)
    8000492a:	6942                	ld	s2,16(sp)
    8000492c:	69a2                	ld	s3,8(sp)
    8000492e:	6145                	addi	sp,sp,48
    80004930:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004932:	0284a983          	lw	s3,40(s1)
    80004936:	ffffd097          	auipc	ra,0xffffd
    8000493a:	100080e7          	jalr	256(ra) # 80001a36 <myproc>
    8000493e:	5904                	lw	s1,48(a0)
    80004940:	413484b3          	sub	s1,s1,s3
    80004944:	0014b493          	seqz	s1,s1
    80004948:	bfc1                	j	80004918 <holdingsleep+0x24>

000000008000494a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000494a:	1141                	addi	sp,sp,-16
    8000494c:	e406                	sd	ra,8(sp)
    8000494e:	e022                	sd	s0,0(sp)
    80004950:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004952:	00004597          	auipc	a1,0x4
    80004956:	d5658593          	addi	a1,a1,-682 # 800086a8 <syscalls+0x258>
    8000495a:	00021517          	auipc	a0,0x21
    8000495e:	96e50513          	addi	a0,a0,-1682 # 800252c8 <ftable>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	1e4080e7          	jalr	484(ra) # 80000b46 <initlock>
}
    8000496a:	60a2                	ld	ra,8(sp)
    8000496c:	6402                	ld	s0,0(sp)
    8000496e:	0141                	addi	sp,sp,16
    80004970:	8082                	ret

0000000080004972 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004972:	1101                	addi	sp,sp,-32
    80004974:	ec06                	sd	ra,24(sp)
    80004976:	e822                	sd	s0,16(sp)
    80004978:	e426                	sd	s1,8(sp)
    8000497a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000497c:	00021517          	auipc	a0,0x21
    80004980:	94c50513          	addi	a0,a0,-1716 # 800252c8 <ftable>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	252080e7          	jalr	594(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000498c:	00021497          	auipc	s1,0x21
    80004990:	95448493          	addi	s1,s1,-1708 # 800252e0 <ftable+0x18>
    80004994:	00022717          	auipc	a4,0x22
    80004998:	8ec70713          	addi	a4,a4,-1812 # 80026280 <disk>
    if(f->ref == 0){
    8000499c:	40dc                	lw	a5,4(s1)
    8000499e:	cf99                	beqz	a5,800049bc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a0:	02848493          	addi	s1,s1,40
    800049a4:	fee49ce3          	bne	s1,a4,8000499c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049a8:	00021517          	auipc	a0,0x21
    800049ac:	92050513          	addi	a0,a0,-1760 # 800252c8 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	2da080e7          	jalr	730(ra) # 80000c8a <release>
  return 0;
    800049b8:	4481                	li	s1,0
    800049ba:	a819                	j	800049d0 <filealloc+0x5e>
      f->ref = 1;
    800049bc:	4785                	li	a5,1
    800049be:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049c0:	00021517          	auipc	a0,0x21
    800049c4:	90850513          	addi	a0,a0,-1784 # 800252c8 <ftable>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	2c2080e7          	jalr	706(ra) # 80000c8a <release>
}
    800049d0:	8526                	mv	a0,s1
    800049d2:	60e2                	ld	ra,24(sp)
    800049d4:	6442                	ld	s0,16(sp)
    800049d6:	64a2                	ld	s1,8(sp)
    800049d8:	6105                	addi	sp,sp,32
    800049da:	8082                	ret

00000000800049dc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049dc:	1101                	addi	sp,sp,-32
    800049de:	ec06                	sd	ra,24(sp)
    800049e0:	e822                	sd	s0,16(sp)
    800049e2:	e426                	sd	s1,8(sp)
    800049e4:	1000                	addi	s0,sp,32
    800049e6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049e8:	00021517          	auipc	a0,0x21
    800049ec:	8e050513          	addi	a0,a0,-1824 # 800252c8 <ftable>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	1e6080e7          	jalr	486(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049f8:	40dc                	lw	a5,4(s1)
    800049fa:	02f05263          	blez	a5,80004a1e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049fe:	2785                	addiw	a5,a5,1
    80004a00:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a02:	00021517          	auipc	a0,0x21
    80004a06:	8c650513          	addi	a0,a0,-1850 # 800252c8 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
  return f;
}
    80004a12:	8526                	mv	a0,s1
    80004a14:	60e2                	ld	ra,24(sp)
    80004a16:	6442                	ld	s0,16(sp)
    80004a18:	64a2                	ld	s1,8(sp)
    80004a1a:	6105                	addi	sp,sp,32
    80004a1c:	8082                	ret
    panic("filedup");
    80004a1e:	00004517          	auipc	a0,0x4
    80004a22:	c9250513          	addi	a0,a0,-878 # 800086b0 <syscalls+0x260>
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	b18080e7          	jalr	-1256(ra) # 8000053e <panic>

0000000080004a2e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a2e:	7139                	addi	sp,sp,-64
    80004a30:	fc06                	sd	ra,56(sp)
    80004a32:	f822                	sd	s0,48(sp)
    80004a34:	f426                	sd	s1,40(sp)
    80004a36:	f04a                	sd	s2,32(sp)
    80004a38:	ec4e                	sd	s3,24(sp)
    80004a3a:	e852                	sd	s4,16(sp)
    80004a3c:	e456                	sd	s5,8(sp)
    80004a3e:	0080                	addi	s0,sp,64
    80004a40:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a42:	00021517          	auipc	a0,0x21
    80004a46:	88650513          	addi	a0,a0,-1914 # 800252c8 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	18c080e7          	jalr	396(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a52:	40dc                	lw	a5,4(s1)
    80004a54:	06f05163          	blez	a5,80004ab6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a58:	37fd                	addiw	a5,a5,-1
    80004a5a:	0007871b          	sext.w	a4,a5
    80004a5e:	c0dc                	sw	a5,4(s1)
    80004a60:	06e04363          	bgtz	a4,80004ac6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a64:	0004a903          	lw	s2,0(s1)
    80004a68:	0094ca83          	lbu	s5,9(s1)
    80004a6c:	0104ba03          	ld	s4,16(s1)
    80004a70:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a74:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a78:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a7c:	00021517          	auipc	a0,0x21
    80004a80:	84c50513          	addi	a0,a0,-1972 # 800252c8 <ftable>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	206080e7          	jalr	518(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004a8c:	4785                	li	a5,1
    80004a8e:	04f90d63          	beq	s2,a5,80004ae8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a92:	3979                	addiw	s2,s2,-2
    80004a94:	4785                	li	a5,1
    80004a96:	0527e063          	bltu	a5,s2,80004ad6 <fileclose+0xa8>
    begin_op();
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	ac8080e7          	jalr	-1336(ra) # 80004562 <begin_op>
    iput(ff.ip);
    80004aa2:	854e                	mv	a0,s3
    80004aa4:	fffff097          	auipc	ra,0xfffff
    80004aa8:	2b6080e7          	jalr	694(ra) # 80003d5a <iput>
    end_op();
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	b36080e7          	jalr	-1226(ra) # 800045e2 <end_op>
    80004ab4:	a00d                	j	80004ad6 <fileclose+0xa8>
    panic("fileclose");
    80004ab6:	00004517          	auipc	a0,0x4
    80004aba:	c0250513          	addi	a0,a0,-1022 # 800086b8 <syscalls+0x268>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	a80080e7          	jalr	-1408(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ac6:	00021517          	auipc	a0,0x21
    80004aca:	80250513          	addi	a0,a0,-2046 # 800252c8 <ftable>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	1bc080e7          	jalr	444(ra) # 80000c8a <release>
  }
}
    80004ad6:	70e2                	ld	ra,56(sp)
    80004ad8:	7442                	ld	s0,48(sp)
    80004ada:	74a2                	ld	s1,40(sp)
    80004adc:	7902                	ld	s2,32(sp)
    80004ade:	69e2                	ld	s3,24(sp)
    80004ae0:	6a42                	ld	s4,16(sp)
    80004ae2:	6aa2                	ld	s5,8(sp)
    80004ae4:	6121                	addi	sp,sp,64
    80004ae6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ae8:	85d6                	mv	a1,s5
    80004aea:	8552                	mv	a0,s4
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	34c080e7          	jalr	844(ra) # 80004e38 <pipeclose>
    80004af4:	b7cd                	j	80004ad6 <fileclose+0xa8>

0000000080004af6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004af6:	715d                	addi	sp,sp,-80
    80004af8:	e486                	sd	ra,72(sp)
    80004afa:	e0a2                	sd	s0,64(sp)
    80004afc:	fc26                	sd	s1,56(sp)
    80004afe:	f84a                	sd	s2,48(sp)
    80004b00:	f44e                	sd	s3,40(sp)
    80004b02:	0880                	addi	s0,sp,80
    80004b04:	84aa                	mv	s1,a0
    80004b06:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	f2e080e7          	jalr	-210(ra) # 80001a36 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b10:	409c                	lw	a5,0(s1)
    80004b12:	37f9                	addiw	a5,a5,-2
    80004b14:	4705                	li	a4,1
    80004b16:	04f76763          	bltu	a4,a5,80004b64 <filestat+0x6e>
    80004b1a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b1c:	6c88                	ld	a0,24(s1)
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	082080e7          	jalr	130(ra) # 80003ba0 <ilock>
    stati(f->ip, &st);
    80004b26:	fb840593          	addi	a1,s0,-72
    80004b2a:	6c88                	ld	a0,24(s1)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	2fe080e7          	jalr	766(ra) # 80003e2a <stati>
    iunlock(f->ip);
    80004b34:	6c88                	ld	a0,24(s1)
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	12c080e7          	jalr	300(ra) # 80003c62 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b3e:	46e1                	li	a3,24
    80004b40:	fb840613          	addi	a2,s0,-72
    80004b44:	85ce                	mv	a1,s3
    80004b46:	05893503          	ld	a0,88(s2)
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	b1e080e7          	jalr	-1250(ra) # 80001668 <copyout>
    80004b52:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b56:	60a6                	ld	ra,72(sp)
    80004b58:	6406                	ld	s0,64(sp)
    80004b5a:	74e2                	ld	s1,56(sp)
    80004b5c:	7942                	ld	s2,48(sp)
    80004b5e:	79a2                	ld	s3,40(sp)
    80004b60:	6161                	addi	sp,sp,80
    80004b62:	8082                	ret
  return -1;
    80004b64:	557d                	li	a0,-1
    80004b66:	bfc5                	j	80004b56 <filestat+0x60>

0000000080004b68 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b68:	7179                	addi	sp,sp,-48
    80004b6a:	f406                	sd	ra,40(sp)
    80004b6c:	f022                	sd	s0,32(sp)
    80004b6e:	ec26                	sd	s1,24(sp)
    80004b70:	e84a                	sd	s2,16(sp)
    80004b72:	e44e                	sd	s3,8(sp)
    80004b74:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b76:	00854783          	lbu	a5,8(a0)
    80004b7a:	c3d5                	beqz	a5,80004c1e <fileread+0xb6>
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	89ae                	mv	s3,a1
    80004b80:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b82:	411c                	lw	a5,0(a0)
    80004b84:	4705                	li	a4,1
    80004b86:	04e78963          	beq	a5,a4,80004bd8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b8a:	470d                	li	a4,3
    80004b8c:	04e78d63          	beq	a5,a4,80004be6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b90:	4709                	li	a4,2
    80004b92:	06e79e63          	bne	a5,a4,80004c0e <fileread+0xa6>
    ilock(f->ip);
    80004b96:	6d08                	ld	a0,24(a0)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	008080e7          	jalr	8(ra) # 80003ba0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ba0:	874a                	mv	a4,s2
    80004ba2:	5094                	lw	a3,32(s1)
    80004ba4:	864e                	mv	a2,s3
    80004ba6:	4585                	li	a1,1
    80004ba8:	6c88                	ld	a0,24(s1)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	2aa080e7          	jalr	682(ra) # 80003e54 <readi>
    80004bb2:	892a                	mv	s2,a0
    80004bb4:	00a05563          	blez	a0,80004bbe <fileread+0x56>
      f->off += r;
    80004bb8:	509c                	lw	a5,32(s1)
    80004bba:	9fa9                	addw	a5,a5,a0
    80004bbc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bbe:	6c88                	ld	a0,24(s1)
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	0a2080e7          	jalr	162(ra) # 80003c62 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bc8:	854a                	mv	a0,s2
    80004bca:	70a2                	ld	ra,40(sp)
    80004bcc:	7402                	ld	s0,32(sp)
    80004bce:	64e2                	ld	s1,24(sp)
    80004bd0:	6942                	ld	s2,16(sp)
    80004bd2:	69a2                	ld	s3,8(sp)
    80004bd4:	6145                	addi	sp,sp,48
    80004bd6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bd8:	6908                	ld	a0,16(a0)
    80004bda:	00000097          	auipc	ra,0x0
    80004bde:	3c6080e7          	jalr	966(ra) # 80004fa0 <piperead>
    80004be2:	892a                	mv	s2,a0
    80004be4:	b7d5                	j	80004bc8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004be6:	02451783          	lh	a5,36(a0)
    80004bea:	03079693          	slli	a3,a5,0x30
    80004bee:	92c1                	srli	a3,a3,0x30
    80004bf0:	4725                	li	a4,9
    80004bf2:	02d76863          	bltu	a4,a3,80004c22 <fileread+0xba>
    80004bf6:	0792                	slli	a5,a5,0x4
    80004bf8:	00020717          	auipc	a4,0x20
    80004bfc:	63070713          	addi	a4,a4,1584 # 80025228 <devsw>
    80004c00:	97ba                	add	a5,a5,a4
    80004c02:	639c                	ld	a5,0(a5)
    80004c04:	c38d                	beqz	a5,80004c26 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c06:	4505                	li	a0,1
    80004c08:	9782                	jalr	a5
    80004c0a:	892a                	mv	s2,a0
    80004c0c:	bf75                	j	80004bc8 <fileread+0x60>
    panic("fileread");
    80004c0e:	00004517          	auipc	a0,0x4
    80004c12:	aba50513          	addi	a0,a0,-1350 # 800086c8 <syscalls+0x278>
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	928080e7          	jalr	-1752(ra) # 8000053e <panic>
    return -1;
    80004c1e:	597d                	li	s2,-1
    80004c20:	b765                	j	80004bc8 <fileread+0x60>
      return -1;
    80004c22:	597d                	li	s2,-1
    80004c24:	b755                	j	80004bc8 <fileread+0x60>
    80004c26:	597d                	li	s2,-1
    80004c28:	b745                	j	80004bc8 <fileread+0x60>

0000000080004c2a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c2a:	715d                	addi	sp,sp,-80
    80004c2c:	e486                	sd	ra,72(sp)
    80004c2e:	e0a2                	sd	s0,64(sp)
    80004c30:	fc26                	sd	s1,56(sp)
    80004c32:	f84a                	sd	s2,48(sp)
    80004c34:	f44e                	sd	s3,40(sp)
    80004c36:	f052                	sd	s4,32(sp)
    80004c38:	ec56                	sd	s5,24(sp)
    80004c3a:	e85a                	sd	s6,16(sp)
    80004c3c:	e45e                	sd	s7,8(sp)
    80004c3e:	e062                	sd	s8,0(sp)
    80004c40:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c42:	00954783          	lbu	a5,9(a0)
    80004c46:	10078663          	beqz	a5,80004d52 <filewrite+0x128>
    80004c4a:	892a                	mv	s2,a0
    80004c4c:	8aae                	mv	s5,a1
    80004c4e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c50:	411c                	lw	a5,0(a0)
    80004c52:	4705                	li	a4,1
    80004c54:	02e78263          	beq	a5,a4,80004c78 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c58:	470d                	li	a4,3
    80004c5a:	02e78663          	beq	a5,a4,80004c86 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c5e:	4709                	li	a4,2
    80004c60:	0ee79163          	bne	a5,a4,80004d42 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c64:	0ac05d63          	blez	a2,80004d1e <filewrite+0xf4>
    int i = 0;
    80004c68:	4981                	li	s3,0
    80004c6a:	6b05                	lui	s6,0x1
    80004c6c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c70:	6b85                	lui	s7,0x1
    80004c72:	c00b8b9b          	addiw	s7,s7,-1024
    80004c76:	a861                	j	80004d0e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c78:	6908                	ld	a0,16(a0)
    80004c7a:	00000097          	auipc	ra,0x0
    80004c7e:	22e080e7          	jalr	558(ra) # 80004ea8 <pipewrite>
    80004c82:	8a2a                	mv	s4,a0
    80004c84:	a045                	j	80004d24 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c86:	02451783          	lh	a5,36(a0)
    80004c8a:	03079693          	slli	a3,a5,0x30
    80004c8e:	92c1                	srli	a3,a3,0x30
    80004c90:	4725                	li	a4,9
    80004c92:	0cd76263          	bltu	a4,a3,80004d56 <filewrite+0x12c>
    80004c96:	0792                	slli	a5,a5,0x4
    80004c98:	00020717          	auipc	a4,0x20
    80004c9c:	59070713          	addi	a4,a4,1424 # 80025228 <devsw>
    80004ca0:	97ba                	add	a5,a5,a4
    80004ca2:	679c                	ld	a5,8(a5)
    80004ca4:	cbdd                	beqz	a5,80004d5a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ca6:	4505                	li	a0,1
    80004ca8:	9782                	jalr	a5
    80004caa:	8a2a                	mv	s4,a0
    80004cac:	a8a5                	j	80004d24 <filewrite+0xfa>
    80004cae:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	8b0080e7          	jalr	-1872(ra) # 80004562 <begin_op>
      ilock(f->ip);
    80004cba:	01893503          	ld	a0,24(s2)
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	ee2080e7          	jalr	-286(ra) # 80003ba0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cc6:	8762                	mv	a4,s8
    80004cc8:	02092683          	lw	a3,32(s2)
    80004ccc:	01598633          	add	a2,s3,s5
    80004cd0:	4585                	li	a1,1
    80004cd2:	01893503          	ld	a0,24(s2)
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	276080e7          	jalr	630(ra) # 80003f4c <writei>
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	00a05763          	blez	a0,80004cee <filewrite+0xc4>
        f->off += r;
    80004ce4:	02092783          	lw	a5,32(s2)
    80004ce8:	9fa9                	addw	a5,a5,a0
    80004cea:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cee:	01893503          	ld	a0,24(s2)
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	f70080e7          	jalr	-144(ra) # 80003c62 <iunlock>
      end_op();
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	8e8080e7          	jalr	-1816(ra) # 800045e2 <end_op>

      if(r != n1){
    80004d02:	009c1f63          	bne	s8,s1,80004d20 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d06:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d0a:	0149db63          	bge	s3,s4,80004d20 <filewrite+0xf6>
      int n1 = n - i;
    80004d0e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d12:	84be                	mv	s1,a5
    80004d14:	2781                	sext.w	a5,a5
    80004d16:	f8fb5ce3          	bge	s6,a5,80004cae <filewrite+0x84>
    80004d1a:	84de                	mv	s1,s7
    80004d1c:	bf49                	j	80004cae <filewrite+0x84>
    int i = 0;
    80004d1e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d20:	013a1f63          	bne	s4,s3,80004d3e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d24:	8552                	mv	a0,s4
    80004d26:	60a6                	ld	ra,72(sp)
    80004d28:	6406                	ld	s0,64(sp)
    80004d2a:	74e2                	ld	s1,56(sp)
    80004d2c:	7942                	ld	s2,48(sp)
    80004d2e:	79a2                	ld	s3,40(sp)
    80004d30:	7a02                	ld	s4,32(sp)
    80004d32:	6ae2                	ld	s5,24(sp)
    80004d34:	6b42                	ld	s6,16(sp)
    80004d36:	6ba2                	ld	s7,8(sp)
    80004d38:	6c02                	ld	s8,0(sp)
    80004d3a:	6161                	addi	sp,sp,80
    80004d3c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d3e:	5a7d                	li	s4,-1
    80004d40:	b7d5                	j	80004d24 <filewrite+0xfa>
    panic("filewrite");
    80004d42:	00004517          	auipc	a0,0x4
    80004d46:	99650513          	addi	a0,a0,-1642 # 800086d8 <syscalls+0x288>
    80004d4a:	ffffb097          	auipc	ra,0xffffb
    80004d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
    return -1;
    80004d52:	5a7d                	li	s4,-1
    80004d54:	bfc1                	j	80004d24 <filewrite+0xfa>
      return -1;
    80004d56:	5a7d                	li	s4,-1
    80004d58:	b7f1                	j	80004d24 <filewrite+0xfa>
    80004d5a:	5a7d                	li	s4,-1
    80004d5c:	b7e1                	j	80004d24 <filewrite+0xfa>

0000000080004d5e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d5e:	7179                	addi	sp,sp,-48
    80004d60:	f406                	sd	ra,40(sp)
    80004d62:	f022                	sd	s0,32(sp)
    80004d64:	ec26                	sd	s1,24(sp)
    80004d66:	e84a                	sd	s2,16(sp)
    80004d68:	e44e                	sd	s3,8(sp)
    80004d6a:	e052                	sd	s4,0(sp)
    80004d6c:	1800                	addi	s0,sp,48
    80004d6e:	84aa                	mv	s1,a0
    80004d70:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d72:	0005b023          	sd	zero,0(a1)
    80004d76:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d7a:	00000097          	auipc	ra,0x0
    80004d7e:	bf8080e7          	jalr	-1032(ra) # 80004972 <filealloc>
    80004d82:	e088                	sd	a0,0(s1)
    80004d84:	c551                	beqz	a0,80004e10 <pipealloc+0xb2>
    80004d86:	00000097          	auipc	ra,0x0
    80004d8a:	bec080e7          	jalr	-1044(ra) # 80004972 <filealloc>
    80004d8e:	00aa3023          	sd	a0,0(s4)
    80004d92:	c92d                	beqz	a0,80004e04 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	d52080e7          	jalr	-686(ra) # 80000ae6 <kalloc>
    80004d9c:	892a                	mv	s2,a0
    80004d9e:	c125                	beqz	a0,80004dfe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004da0:	4985                	li	s3,1
    80004da2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004da6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004daa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dae:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004db2:	00004597          	auipc	a1,0x4
    80004db6:	93658593          	addi	a1,a1,-1738 # 800086e8 <syscalls+0x298>
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	d8c080e7          	jalr	-628(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004dc2:	609c                	ld	a5,0(s1)
    80004dc4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dc8:	609c                	ld	a5,0(s1)
    80004dca:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dce:	609c                	ld	a5,0(s1)
    80004dd0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dd4:	609c                	ld	a5,0(s1)
    80004dd6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dda:	000a3783          	ld	a5,0(s4)
    80004dde:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004de2:	000a3783          	ld	a5,0(s4)
    80004de6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dea:	000a3783          	ld	a5,0(s4)
    80004dee:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004df2:	000a3783          	ld	a5,0(s4)
    80004df6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dfa:	4501                	li	a0,0
    80004dfc:	a025                	j	80004e24 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dfe:	6088                	ld	a0,0(s1)
    80004e00:	e501                	bnez	a0,80004e08 <pipealloc+0xaa>
    80004e02:	a039                	j	80004e10 <pipealloc+0xb2>
    80004e04:	6088                	ld	a0,0(s1)
    80004e06:	c51d                	beqz	a0,80004e34 <pipealloc+0xd6>
    fileclose(*f0);
    80004e08:	00000097          	auipc	ra,0x0
    80004e0c:	c26080e7          	jalr	-986(ra) # 80004a2e <fileclose>
  if(*f1)
    80004e10:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e14:	557d                	li	a0,-1
  if(*f1)
    80004e16:	c799                	beqz	a5,80004e24 <pipealloc+0xc6>
    fileclose(*f1);
    80004e18:	853e                	mv	a0,a5
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	c14080e7          	jalr	-1004(ra) # 80004a2e <fileclose>
  return -1;
    80004e22:	557d                	li	a0,-1
}
    80004e24:	70a2                	ld	ra,40(sp)
    80004e26:	7402                	ld	s0,32(sp)
    80004e28:	64e2                	ld	s1,24(sp)
    80004e2a:	6942                	ld	s2,16(sp)
    80004e2c:	69a2                	ld	s3,8(sp)
    80004e2e:	6a02                	ld	s4,0(sp)
    80004e30:	6145                	addi	sp,sp,48
    80004e32:	8082                	ret
  return -1;
    80004e34:	557d                	li	a0,-1
    80004e36:	b7fd                	j	80004e24 <pipealloc+0xc6>

0000000080004e38 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e38:	1101                	addi	sp,sp,-32
    80004e3a:	ec06                	sd	ra,24(sp)
    80004e3c:	e822                	sd	s0,16(sp)
    80004e3e:	e426                	sd	s1,8(sp)
    80004e40:	e04a                	sd	s2,0(sp)
    80004e42:	1000                	addi	s0,sp,32
    80004e44:	84aa                	mv	s1,a0
    80004e46:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	d8e080e7          	jalr	-626(ra) # 80000bd6 <acquire>
  if(writable){
    80004e50:	02090d63          	beqz	s2,80004e8a <pipeclose+0x52>
    pi->writeopen = 0;
    80004e54:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e58:	21848513          	addi	a0,s1,536
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	3c8080e7          	jalr	968(ra) # 80002224 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e64:	2204b783          	ld	a5,544(s1)
    80004e68:	eb95                	bnez	a5,80004e9c <pipeclose+0x64>
    release(&pi->lock);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	b74080e7          	jalr	-1164(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004e7e:	60e2                	ld	ra,24(sp)
    80004e80:	6442                	ld	s0,16(sp)
    80004e82:	64a2                	ld	s1,8(sp)
    80004e84:	6902                	ld	s2,0(sp)
    80004e86:	6105                	addi	sp,sp,32
    80004e88:	8082                	ret
    pi->readopen = 0;
    80004e8a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e8e:	21c48513          	addi	a0,s1,540
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	392080e7          	jalr	914(ra) # 80002224 <wakeup>
    80004e9a:	b7e9                	j	80004e64 <pipeclose+0x2c>
    release(&pi->lock);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	dec080e7          	jalr	-532(ra) # 80000c8a <release>
}
    80004ea6:	bfe1                	j	80004e7e <pipeclose+0x46>

0000000080004ea8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ea8:	711d                	addi	sp,sp,-96
    80004eaa:	ec86                	sd	ra,88(sp)
    80004eac:	e8a2                	sd	s0,80(sp)
    80004eae:	e4a6                	sd	s1,72(sp)
    80004eb0:	e0ca                	sd	s2,64(sp)
    80004eb2:	fc4e                	sd	s3,56(sp)
    80004eb4:	f852                	sd	s4,48(sp)
    80004eb6:	f456                	sd	s5,40(sp)
    80004eb8:	f05a                	sd	s6,32(sp)
    80004eba:	ec5e                	sd	s7,24(sp)
    80004ebc:	e862                	sd	s8,16(sp)
    80004ebe:	1080                	addi	s0,sp,96
    80004ec0:	84aa                	mv	s1,a0
    80004ec2:	8aae                	mv	s5,a1
    80004ec4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	b70080e7          	jalr	-1168(ra) # 80001a36 <myproc>
    80004ece:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	d04080e7          	jalr	-764(ra) # 80000bd6 <acquire>
  while(i < n){
    80004eda:	0b405663          	blez	s4,80004f86 <pipewrite+0xde>
  int i = 0;
    80004ede:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ee2:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ee6:	21c48b93          	addi	s7,s1,540
    80004eea:	a089                	j	80004f2c <pipewrite+0x84>
      release(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	d9c080e7          	jalr	-612(ra) # 80000c8a <release>
      return -1;
    80004ef6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ef8:	854a                	mv	a0,s2
    80004efa:	60e6                	ld	ra,88(sp)
    80004efc:	6446                	ld	s0,80(sp)
    80004efe:	64a6                	ld	s1,72(sp)
    80004f00:	6906                	ld	s2,64(sp)
    80004f02:	79e2                	ld	s3,56(sp)
    80004f04:	7a42                	ld	s4,48(sp)
    80004f06:	7aa2                	ld	s5,40(sp)
    80004f08:	7b02                	ld	s6,32(sp)
    80004f0a:	6be2                	ld	s7,24(sp)
    80004f0c:	6c42                	ld	s8,16(sp)
    80004f0e:	6125                	addi	sp,sp,96
    80004f10:	8082                	ret
      wakeup(&pi->nread);
    80004f12:	8562                	mv	a0,s8
    80004f14:	ffffd097          	auipc	ra,0xffffd
    80004f18:	310080e7          	jalr	784(ra) # 80002224 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f1c:	85a6                	mv	a1,s1
    80004f1e:	855e                	mv	a0,s7
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	2a0080e7          	jalr	672(ra) # 800021c0 <sleep>
  while(i < n){
    80004f28:	07495063          	bge	s2,s4,80004f88 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f2c:	2204a783          	lw	a5,544(s1)
    80004f30:	dfd5                	beqz	a5,80004eec <pipewrite+0x44>
    80004f32:	854e                	mv	a0,s3
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	540080e7          	jalr	1344(ra) # 80002474 <killed>
    80004f3c:	f945                	bnez	a0,80004eec <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f3e:	2184a783          	lw	a5,536(s1)
    80004f42:	21c4a703          	lw	a4,540(s1)
    80004f46:	2007879b          	addiw	a5,a5,512
    80004f4a:	fcf704e3          	beq	a4,a5,80004f12 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f4e:	4685                	li	a3,1
    80004f50:	01590633          	add	a2,s2,s5
    80004f54:	faf40593          	addi	a1,s0,-81
    80004f58:	0589b503          	ld	a0,88(s3)
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	798080e7          	jalr	1944(ra) # 800016f4 <copyin>
    80004f64:	03650263          	beq	a0,s6,80004f88 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f68:	21c4a783          	lw	a5,540(s1)
    80004f6c:	0017871b          	addiw	a4,a5,1
    80004f70:	20e4ae23          	sw	a4,540(s1)
    80004f74:	1ff7f793          	andi	a5,a5,511
    80004f78:	97a6                	add	a5,a5,s1
    80004f7a:	faf44703          	lbu	a4,-81(s0)
    80004f7e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f82:	2905                	addiw	s2,s2,1
    80004f84:	b755                	j	80004f28 <pipewrite+0x80>
  int i = 0;
    80004f86:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f88:	21848513          	addi	a0,s1,536
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	298080e7          	jalr	664(ra) # 80002224 <wakeup>
  release(&pi->lock);
    80004f94:	8526                	mv	a0,s1
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	cf4080e7          	jalr	-780(ra) # 80000c8a <release>
  return i;
    80004f9e:	bfa9                	j	80004ef8 <pipewrite+0x50>

0000000080004fa0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fa0:	715d                	addi	sp,sp,-80
    80004fa2:	e486                	sd	ra,72(sp)
    80004fa4:	e0a2                	sd	s0,64(sp)
    80004fa6:	fc26                	sd	s1,56(sp)
    80004fa8:	f84a                	sd	s2,48(sp)
    80004faa:	f44e                	sd	s3,40(sp)
    80004fac:	f052                	sd	s4,32(sp)
    80004fae:	ec56                	sd	s5,24(sp)
    80004fb0:	e85a                	sd	s6,16(sp)
    80004fb2:	0880                	addi	s0,sp,80
    80004fb4:	84aa                	mv	s1,a0
    80004fb6:	892e                	mv	s2,a1
    80004fb8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	a7c080e7          	jalr	-1412(ra) # 80001a36 <myproc>
    80004fc2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fce:	2184a703          	lw	a4,536(s1)
    80004fd2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	02f71763          	bne	a4,a5,80005008 <piperead+0x68>
    80004fde:	2244a783          	lw	a5,548(s1)
    80004fe2:	c39d                	beqz	a5,80005008 <piperead+0x68>
    if(killed(pr)){
    80004fe4:	8552                	mv	a0,s4
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	48e080e7          	jalr	1166(ra) # 80002474 <killed>
    80004fee:	e941                	bnez	a0,8000507e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ff0:	85a6                	mv	a1,s1
    80004ff2:	854e                	mv	a0,s3
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	1cc080e7          	jalr	460(ra) # 800021c0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ffc:	2184a703          	lw	a4,536(s1)
    80005000:	21c4a783          	lw	a5,540(s1)
    80005004:	fcf70de3          	beq	a4,a5,80004fde <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005008:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000500a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000500c:	05505363          	blez	s5,80005052 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005010:	2184a783          	lw	a5,536(s1)
    80005014:	21c4a703          	lw	a4,540(s1)
    80005018:	02f70d63          	beq	a4,a5,80005052 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000501c:	0017871b          	addiw	a4,a5,1
    80005020:	20e4ac23          	sw	a4,536(s1)
    80005024:	1ff7f793          	andi	a5,a5,511
    80005028:	97a6                	add	a5,a5,s1
    8000502a:	0187c783          	lbu	a5,24(a5)
    8000502e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005032:	4685                	li	a3,1
    80005034:	fbf40613          	addi	a2,s0,-65
    80005038:	85ca                	mv	a1,s2
    8000503a:	058a3503          	ld	a0,88(s4)
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	62a080e7          	jalr	1578(ra) # 80001668 <copyout>
    80005046:	01650663          	beq	a0,s6,80005052 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000504a:	2985                	addiw	s3,s3,1
    8000504c:	0905                	addi	s2,s2,1
    8000504e:	fd3a91e3          	bne	s5,s3,80005010 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005052:	21c48513          	addi	a0,s1,540
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	1ce080e7          	jalr	462(ra) # 80002224 <wakeup>
  release(&pi->lock);
    8000505e:	8526                	mv	a0,s1
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	c2a080e7          	jalr	-982(ra) # 80000c8a <release>
  return i;
}
    80005068:	854e                	mv	a0,s3
    8000506a:	60a6                	ld	ra,72(sp)
    8000506c:	6406                	ld	s0,64(sp)
    8000506e:	74e2                	ld	s1,56(sp)
    80005070:	7942                	ld	s2,48(sp)
    80005072:	79a2                	ld	s3,40(sp)
    80005074:	7a02                	ld	s4,32(sp)
    80005076:	6ae2                	ld	s5,24(sp)
    80005078:	6b42                	ld	s6,16(sp)
    8000507a:	6161                	addi	sp,sp,80
    8000507c:	8082                	ret
      release(&pi->lock);
    8000507e:	8526                	mv	a0,s1
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	c0a080e7          	jalr	-1014(ra) # 80000c8a <release>
      return -1;
    80005088:	59fd                	li	s3,-1
    8000508a:	bff9                	j	80005068 <piperead+0xc8>

000000008000508c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000508c:	1141                	addi	sp,sp,-16
    8000508e:	e422                	sd	s0,8(sp)
    80005090:	0800                	addi	s0,sp,16
    80005092:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005094:	8905                	andi	a0,a0,1
    80005096:	c111                	beqz	a0,8000509a <flags2perm+0xe>
      perm = PTE_X;
    80005098:	4521                	li	a0,8
    if(flags & 0x2)
    8000509a:	8b89                	andi	a5,a5,2
    8000509c:	c399                	beqz	a5,800050a2 <flags2perm+0x16>
      perm |= PTE_W;
    8000509e:	00456513          	ori	a0,a0,4
    return perm;
}
    800050a2:	6422                	ld	s0,8(sp)
    800050a4:	0141                	addi	sp,sp,16
    800050a6:	8082                	ret

00000000800050a8 <exec>:

int
exec(char *path, char **argv)
{
    800050a8:	de010113          	addi	sp,sp,-544
    800050ac:	20113c23          	sd	ra,536(sp)
    800050b0:	20813823          	sd	s0,528(sp)
    800050b4:	20913423          	sd	s1,520(sp)
    800050b8:	21213023          	sd	s2,512(sp)
    800050bc:	ffce                	sd	s3,504(sp)
    800050be:	fbd2                	sd	s4,496(sp)
    800050c0:	f7d6                	sd	s5,488(sp)
    800050c2:	f3da                	sd	s6,480(sp)
    800050c4:	efde                	sd	s7,472(sp)
    800050c6:	ebe2                	sd	s8,464(sp)
    800050c8:	e7e6                	sd	s9,456(sp)
    800050ca:	e3ea                	sd	s10,448(sp)
    800050cc:	ff6e                	sd	s11,440(sp)
    800050ce:	1400                	addi	s0,sp,544
    800050d0:	892a                	mv	s2,a0
    800050d2:	dea43423          	sd	a0,-536(s0)
    800050d6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	95c080e7          	jalr	-1700(ra) # 80001a36 <myproc>
    800050e2:	84aa                	mv	s1,a0

  begin_op();
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	47e080e7          	jalr	1150(ra) # 80004562 <begin_op>

  if((ip = namei(path)) == 0){
    800050ec:	854a                	mv	a0,s2
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	258080e7          	jalr	600(ra) # 80004346 <namei>
    800050f6:	c93d                	beqz	a0,8000516c <exec+0xc4>
    800050f8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	aa6080e7          	jalr	-1370(ra) # 80003ba0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005102:	04000713          	li	a4,64
    80005106:	4681                	li	a3,0
    80005108:	e5040613          	addi	a2,s0,-432
    8000510c:	4581                	li	a1,0
    8000510e:	8556                	mv	a0,s5
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	d44080e7          	jalr	-700(ra) # 80003e54 <readi>
    80005118:	04000793          	li	a5,64
    8000511c:	00f51a63          	bne	a0,a5,80005130 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005120:	e5042703          	lw	a4,-432(s0)
    80005124:	464c47b7          	lui	a5,0x464c4
    80005128:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000512c:	04f70663          	beq	a4,a5,80005178 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005130:	8556                	mv	a0,s5
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	cd0080e7          	jalr	-816(ra) # 80003e02 <iunlockput>
    end_op();
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	4a8080e7          	jalr	1192(ra) # 800045e2 <end_op>
  }
  return -1;
    80005142:	557d                	li	a0,-1
}
    80005144:	21813083          	ld	ra,536(sp)
    80005148:	21013403          	ld	s0,528(sp)
    8000514c:	20813483          	ld	s1,520(sp)
    80005150:	20013903          	ld	s2,512(sp)
    80005154:	79fe                	ld	s3,504(sp)
    80005156:	7a5e                	ld	s4,496(sp)
    80005158:	7abe                	ld	s5,488(sp)
    8000515a:	7b1e                	ld	s6,480(sp)
    8000515c:	6bfe                	ld	s7,472(sp)
    8000515e:	6c5e                	ld	s8,464(sp)
    80005160:	6cbe                	ld	s9,456(sp)
    80005162:	6d1e                	ld	s10,448(sp)
    80005164:	7dfa                	ld	s11,440(sp)
    80005166:	22010113          	addi	sp,sp,544
    8000516a:	8082                	ret
    end_op();
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	476080e7          	jalr	1142(ra) # 800045e2 <end_op>
    return -1;
    80005174:	557d                	li	a0,-1
    80005176:	b7f9                	j	80005144 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005178:	8526                	mv	a0,s1
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	9e0080e7          	jalr	-1568(ra) # 80001b5a <proc_pagetable>
    80005182:	8b2a                	mv	s6,a0
    80005184:	d555                	beqz	a0,80005130 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005186:	e7042783          	lw	a5,-400(s0)
    8000518a:	e8845703          	lhu	a4,-376(s0)
    8000518e:	c735                	beqz	a4,800051fa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005190:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005192:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005196:	6a05                	lui	s4,0x1
    80005198:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000519c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800051a0:	6d85                	lui	s11,0x1
    800051a2:	7d7d                	lui	s10,0xfffff
    800051a4:	a481                	j	800053e4 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051a6:	00003517          	auipc	a0,0x3
    800051aa:	54a50513          	addi	a0,a0,1354 # 800086f0 <syscalls+0x2a0>
    800051ae:	ffffb097          	auipc	ra,0xffffb
    800051b2:	390080e7          	jalr	912(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051b6:	874a                	mv	a4,s2
    800051b8:	009c86bb          	addw	a3,s9,s1
    800051bc:	4581                	li	a1,0
    800051be:	8556                	mv	a0,s5
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	c94080e7          	jalr	-876(ra) # 80003e54 <readi>
    800051c8:	2501                	sext.w	a0,a0
    800051ca:	1aa91a63          	bne	s2,a0,8000537e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    800051ce:	009d84bb          	addw	s1,s11,s1
    800051d2:	013d09bb          	addw	s3,s10,s3
    800051d6:	1f74f763          	bgeu	s1,s7,800053c4 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800051da:	02049593          	slli	a1,s1,0x20
    800051de:	9181                	srli	a1,a1,0x20
    800051e0:	95e2                	add	a1,a1,s8
    800051e2:	855a                	mv	a0,s6
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	e78080e7          	jalr	-392(ra) # 8000105c <walkaddr>
    800051ec:	862a                	mv	a2,a0
    if(pa == 0)
    800051ee:	dd45                	beqz	a0,800051a6 <exec+0xfe>
      n = PGSIZE;
    800051f0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800051f2:	fd49f2e3          	bgeu	s3,s4,800051b6 <exec+0x10e>
      n = sz - i;
    800051f6:	894e                	mv	s2,s3
    800051f8:	bf7d                	j	800051b6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051fa:	4901                	li	s2,0
  iunlockput(ip);
    800051fc:	8556                	mv	a0,s5
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	c04080e7          	jalr	-1020(ra) # 80003e02 <iunlockput>
  end_op();
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	3dc080e7          	jalr	988(ra) # 800045e2 <end_op>
  p = myproc();
    8000520e:	ffffd097          	auipc	ra,0xffffd
    80005212:	828080e7          	jalr	-2008(ra) # 80001a36 <myproc>
    80005216:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005218:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000521c:	6785                	lui	a5,0x1
    8000521e:	17fd                	addi	a5,a5,-1
    80005220:	993e                	add	s2,s2,a5
    80005222:	77fd                	lui	a5,0xfffff
    80005224:	00f977b3          	and	a5,s2,a5
    80005228:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000522c:	4691                	li	a3,4
    8000522e:	6609                	lui	a2,0x2
    80005230:	963e                	add	a2,a2,a5
    80005232:	85be                	mv	a1,a5
    80005234:	855a                	mv	a0,s6
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	1da080e7          	jalr	474(ra) # 80001410 <uvmalloc>
    8000523e:	8c2a                	mv	s8,a0
  ip = 0;
    80005240:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005242:	12050e63          	beqz	a0,8000537e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005246:	75f9                	lui	a1,0xffffe
    80005248:	95aa                	add	a1,a1,a0
    8000524a:	855a                	mv	a0,s6
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	3ea080e7          	jalr	1002(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80005254:	7afd                	lui	s5,0xfffff
    80005256:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005258:	df043783          	ld	a5,-528(s0)
    8000525c:	6388                	ld	a0,0(a5)
    8000525e:	c925                	beqz	a0,800052ce <exec+0x226>
    80005260:	e9040993          	addi	s3,s0,-368
    80005264:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005268:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000526a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000526c:	ffffc097          	auipc	ra,0xffffc
    80005270:	be2080e7          	jalr	-1054(ra) # 80000e4e <strlen>
    80005274:	0015079b          	addiw	a5,a0,1
    80005278:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000527c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005280:	13596663          	bltu	s2,s5,800053ac <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005284:	df043d83          	ld	s11,-528(s0)
    80005288:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000528c:	8552                	mv	a0,s4
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	bc0080e7          	jalr	-1088(ra) # 80000e4e <strlen>
    80005296:	0015069b          	addiw	a3,a0,1
    8000529a:	8652                	mv	a2,s4
    8000529c:	85ca                	mv	a1,s2
    8000529e:	855a                	mv	a0,s6
    800052a0:	ffffc097          	auipc	ra,0xffffc
    800052a4:	3c8080e7          	jalr	968(ra) # 80001668 <copyout>
    800052a8:	10054663          	bltz	a0,800053b4 <exec+0x30c>
    ustack[argc] = sp;
    800052ac:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052b0:	0485                	addi	s1,s1,1
    800052b2:	008d8793          	addi	a5,s11,8
    800052b6:	def43823          	sd	a5,-528(s0)
    800052ba:	008db503          	ld	a0,8(s11)
    800052be:	c911                	beqz	a0,800052d2 <exec+0x22a>
    if(argc >= MAXARG)
    800052c0:	09a1                	addi	s3,s3,8
    800052c2:	fb3c95e3          	bne	s9,s3,8000526c <exec+0x1c4>
  sz = sz1;
    800052c6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ca:	4a81                	li	s5,0
    800052cc:	a84d                	j	8000537e <exec+0x2d6>
  sp = sz;
    800052ce:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052d0:	4481                	li	s1,0
  ustack[argc] = 0;
    800052d2:	00349793          	slli	a5,s1,0x3
    800052d6:	f9040713          	addi	a4,s0,-112
    800052da:	97ba                	add	a5,a5,a4
    800052dc:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8b40>
  sp -= (argc+1) * sizeof(uint64);
    800052e0:	00148693          	addi	a3,s1,1
    800052e4:	068e                	slli	a3,a3,0x3
    800052e6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052ea:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052ee:	01597663          	bgeu	s2,s5,800052fa <exec+0x252>
  sz = sz1;
    800052f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052f6:	4a81                	li	s5,0
    800052f8:	a059                	j	8000537e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052fa:	e9040613          	addi	a2,s0,-368
    800052fe:	85ca                	mv	a1,s2
    80005300:	855a                	mv	a0,s6
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	366080e7          	jalr	870(ra) # 80001668 <copyout>
    8000530a:	0a054963          	bltz	a0,800053bc <exec+0x314>
  p->trapframe->a1 = sp;
    8000530e:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    80005312:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005316:	de843783          	ld	a5,-536(s0)
    8000531a:	0007c703          	lbu	a4,0(a5)
    8000531e:	cf11                	beqz	a4,8000533a <exec+0x292>
    80005320:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005322:	02f00693          	li	a3,47
    80005326:	a039                	j	80005334 <exec+0x28c>
      last = s+1;
    80005328:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000532c:	0785                	addi	a5,a5,1
    8000532e:	fff7c703          	lbu	a4,-1(a5)
    80005332:	c701                	beqz	a4,8000533a <exec+0x292>
    if(*s == '/')
    80005334:	fed71ce3          	bne	a4,a3,8000532c <exec+0x284>
    80005338:	bfc5                	j	80005328 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000533a:	4641                	li	a2,16
    8000533c:	de843583          	ld	a1,-536(s0)
    80005340:	160b8513          	addi	a0,s7,352
    80005344:	ffffc097          	auipc	ra,0xffffc
    80005348:	ad8080e7          	jalr	-1320(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000534c:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005350:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005354:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005358:	060bb783          	ld	a5,96(s7)
    8000535c:	e6843703          	ld	a4,-408(s0)
    80005360:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005362:	060bb783          	ld	a5,96(s7)
    80005366:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000536a:	85ea                	mv	a1,s10
    8000536c:	ffffd097          	auipc	ra,0xffffd
    80005370:	88a080e7          	jalr	-1910(ra) # 80001bf6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005374:	0004851b          	sext.w	a0,s1
    80005378:	b3f1                	j	80005144 <exec+0x9c>
    8000537a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000537e:	df843583          	ld	a1,-520(s0)
    80005382:	855a                	mv	a0,s6
    80005384:	ffffd097          	auipc	ra,0xffffd
    80005388:	872080e7          	jalr	-1934(ra) # 80001bf6 <proc_freepagetable>
  if(ip){
    8000538c:	da0a92e3          	bnez	s5,80005130 <exec+0x88>
  return -1;
    80005390:	557d                	li	a0,-1
    80005392:	bb4d                	j	80005144 <exec+0x9c>
    80005394:	df243c23          	sd	s2,-520(s0)
    80005398:	b7dd                	j	8000537e <exec+0x2d6>
    8000539a:	df243c23          	sd	s2,-520(s0)
    8000539e:	b7c5                	j	8000537e <exec+0x2d6>
    800053a0:	df243c23          	sd	s2,-520(s0)
    800053a4:	bfe9                	j	8000537e <exec+0x2d6>
    800053a6:	df243c23          	sd	s2,-520(s0)
    800053aa:	bfd1                	j	8000537e <exec+0x2d6>
  sz = sz1;
    800053ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053b0:	4a81                	li	s5,0
    800053b2:	b7f1                	j	8000537e <exec+0x2d6>
  sz = sz1;
    800053b4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053b8:	4a81                	li	s5,0
    800053ba:	b7d1                	j	8000537e <exec+0x2d6>
  sz = sz1;
    800053bc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053c0:	4a81                	li	s5,0
    800053c2:	bf75                	j	8000537e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053c4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c8:	e0843783          	ld	a5,-504(s0)
    800053cc:	0017869b          	addiw	a3,a5,1
    800053d0:	e0d43423          	sd	a3,-504(s0)
    800053d4:	e0043783          	ld	a5,-512(s0)
    800053d8:	0387879b          	addiw	a5,a5,56
    800053dc:	e8845703          	lhu	a4,-376(s0)
    800053e0:	e0e6dee3          	bge	a3,a4,800051fc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053e4:	2781                	sext.w	a5,a5
    800053e6:	e0f43023          	sd	a5,-512(s0)
    800053ea:	03800713          	li	a4,56
    800053ee:	86be                	mv	a3,a5
    800053f0:	e1840613          	addi	a2,s0,-488
    800053f4:	4581                	li	a1,0
    800053f6:	8556                	mv	a0,s5
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	a5c080e7          	jalr	-1444(ra) # 80003e54 <readi>
    80005400:	03800793          	li	a5,56
    80005404:	f6f51be3          	bne	a0,a5,8000537a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005408:	e1842783          	lw	a5,-488(s0)
    8000540c:	4705                	li	a4,1
    8000540e:	fae79de3          	bne	a5,a4,800053c8 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005412:	e4043483          	ld	s1,-448(s0)
    80005416:	e3843783          	ld	a5,-456(s0)
    8000541a:	f6f4ede3          	bltu	s1,a5,80005394 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000541e:	e2843783          	ld	a5,-472(s0)
    80005422:	94be                	add	s1,s1,a5
    80005424:	f6f4ebe3          	bltu	s1,a5,8000539a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005428:	de043703          	ld	a4,-544(s0)
    8000542c:	8ff9                	and	a5,a5,a4
    8000542e:	fbad                	bnez	a5,800053a0 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005430:	e1c42503          	lw	a0,-484(s0)
    80005434:	00000097          	auipc	ra,0x0
    80005438:	c58080e7          	jalr	-936(ra) # 8000508c <flags2perm>
    8000543c:	86aa                	mv	a3,a0
    8000543e:	8626                	mv	a2,s1
    80005440:	85ca                	mv	a1,s2
    80005442:	855a                	mv	a0,s6
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	fcc080e7          	jalr	-52(ra) # 80001410 <uvmalloc>
    8000544c:	dea43c23          	sd	a0,-520(s0)
    80005450:	d939                	beqz	a0,800053a6 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005452:	e2843c03          	ld	s8,-472(s0)
    80005456:	e2042c83          	lw	s9,-480(s0)
    8000545a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000545e:	f60b83e3          	beqz	s7,800053c4 <exec+0x31c>
    80005462:	89de                	mv	s3,s7
    80005464:	4481                	li	s1,0
    80005466:	bb95                	j	800051da <exec+0x132>

0000000080005468 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005468:	7179                	addi	sp,sp,-48
    8000546a:	f406                	sd	ra,40(sp)
    8000546c:	f022                	sd	s0,32(sp)
    8000546e:	ec26                	sd	s1,24(sp)
    80005470:	e84a                	sd	s2,16(sp)
    80005472:	1800                	addi	s0,sp,48
    80005474:	892e                	mv	s2,a1
    80005476:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005478:	fdc40593          	addi	a1,s0,-36
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	a00080e7          	jalr	-1536(ra) # 80002e7c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005484:	fdc42703          	lw	a4,-36(s0)
    80005488:	47bd                	li	a5,15
    8000548a:	02e7eb63          	bltu	a5,a4,800054c0 <argfd+0x58>
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	5a8080e7          	jalr	1448(ra) # 80001a36 <myproc>
    80005496:	fdc42703          	lw	a4,-36(s0)
    8000549a:	01a70793          	addi	a5,a4,26
    8000549e:	078e                	slli	a5,a5,0x3
    800054a0:	953e                	add	a0,a0,a5
    800054a2:	651c                	ld	a5,8(a0)
    800054a4:	c385                	beqz	a5,800054c4 <argfd+0x5c>
    return -1;
  if(pfd)
    800054a6:	00090463          	beqz	s2,800054ae <argfd+0x46>
    *pfd = fd;
    800054aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054ae:	4501                	li	a0,0
  if(pf)
    800054b0:	c091                	beqz	s1,800054b4 <argfd+0x4c>
    *pf = f;
    800054b2:	e09c                	sd	a5,0(s1)
}
    800054b4:	70a2                	ld	ra,40(sp)
    800054b6:	7402                	ld	s0,32(sp)
    800054b8:	64e2                	ld	s1,24(sp)
    800054ba:	6942                	ld	s2,16(sp)
    800054bc:	6145                	addi	sp,sp,48
    800054be:	8082                	ret
    return -1;
    800054c0:	557d                	li	a0,-1
    800054c2:	bfcd                	j	800054b4 <argfd+0x4c>
    800054c4:	557d                	li	a0,-1
    800054c6:	b7fd                	j	800054b4 <argfd+0x4c>

00000000800054c8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054c8:	1101                	addi	sp,sp,-32
    800054ca:	ec06                	sd	ra,24(sp)
    800054cc:	e822                	sd	s0,16(sp)
    800054ce:	e426                	sd	s1,8(sp)
    800054d0:	1000                	addi	s0,sp,32
    800054d2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054d4:	ffffc097          	auipc	ra,0xffffc
    800054d8:	562080e7          	jalr	1378(ra) # 80001a36 <myproc>
    800054dc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054de:	0d850793          	addi	a5,a0,216
    800054e2:	4501                	li	a0,0
    800054e4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054e6:	6398                	ld	a4,0(a5)
    800054e8:	cb19                	beqz	a4,800054fe <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054ea:	2505                	addiw	a0,a0,1
    800054ec:	07a1                	addi	a5,a5,8
    800054ee:	fed51ce3          	bne	a0,a3,800054e6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054f2:	557d                	li	a0,-1
}
    800054f4:	60e2                	ld	ra,24(sp)
    800054f6:	6442                	ld	s0,16(sp)
    800054f8:	64a2                	ld	s1,8(sp)
    800054fa:	6105                	addi	sp,sp,32
    800054fc:	8082                	ret
      p->ofile[fd] = f;
    800054fe:	01a50793          	addi	a5,a0,26
    80005502:	078e                	slli	a5,a5,0x3
    80005504:	963e                	add	a2,a2,a5
    80005506:	e604                	sd	s1,8(a2)
      return fd;
    80005508:	b7f5                	j	800054f4 <fdalloc+0x2c>

000000008000550a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000550a:	715d                	addi	sp,sp,-80
    8000550c:	e486                	sd	ra,72(sp)
    8000550e:	e0a2                	sd	s0,64(sp)
    80005510:	fc26                	sd	s1,56(sp)
    80005512:	f84a                	sd	s2,48(sp)
    80005514:	f44e                	sd	s3,40(sp)
    80005516:	f052                	sd	s4,32(sp)
    80005518:	ec56                	sd	s5,24(sp)
    8000551a:	e85a                	sd	s6,16(sp)
    8000551c:	0880                	addi	s0,sp,80
    8000551e:	8b2e                	mv	s6,a1
    80005520:	89b2                	mv	s3,a2
    80005522:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005524:	fb040593          	addi	a1,s0,-80
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	e3c080e7          	jalr	-452(ra) # 80004364 <nameiparent>
    80005530:	84aa                	mv	s1,a0
    80005532:	14050f63          	beqz	a0,80005690 <create+0x186>
    return 0;

  ilock(dp);
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	66a080e7          	jalr	1642(ra) # 80003ba0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000553e:	4601                	li	a2,0
    80005540:	fb040593          	addi	a1,s0,-80
    80005544:	8526                	mv	a0,s1
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	b3e080e7          	jalr	-1218(ra) # 80004084 <dirlookup>
    8000554e:	8aaa                	mv	s5,a0
    80005550:	c931                	beqz	a0,800055a4 <create+0x9a>
    iunlockput(dp);
    80005552:	8526                	mv	a0,s1
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	8ae080e7          	jalr	-1874(ra) # 80003e02 <iunlockput>
    ilock(ip);
    8000555c:	8556                	mv	a0,s5
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	642080e7          	jalr	1602(ra) # 80003ba0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005566:	000b059b          	sext.w	a1,s6
    8000556a:	4789                	li	a5,2
    8000556c:	02f59563          	bne	a1,a5,80005596 <create+0x8c>
    80005570:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd8c84>
    80005574:	37f9                	addiw	a5,a5,-2
    80005576:	17c2                	slli	a5,a5,0x30
    80005578:	93c1                	srli	a5,a5,0x30
    8000557a:	4705                	li	a4,1
    8000557c:	00f76d63          	bltu	a4,a5,80005596 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005580:	8556                	mv	a0,s5
    80005582:	60a6                	ld	ra,72(sp)
    80005584:	6406                	ld	s0,64(sp)
    80005586:	74e2                	ld	s1,56(sp)
    80005588:	7942                	ld	s2,48(sp)
    8000558a:	79a2                	ld	s3,40(sp)
    8000558c:	7a02                	ld	s4,32(sp)
    8000558e:	6ae2                	ld	s5,24(sp)
    80005590:	6b42                	ld	s6,16(sp)
    80005592:	6161                	addi	sp,sp,80
    80005594:	8082                	ret
    iunlockput(ip);
    80005596:	8556                	mv	a0,s5
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	86a080e7          	jalr	-1942(ra) # 80003e02 <iunlockput>
    return 0;
    800055a0:	4a81                	li	s5,0
    800055a2:	bff9                	j	80005580 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055a4:	85da                	mv	a1,s6
    800055a6:	4088                	lw	a0,0(s1)
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	45c080e7          	jalr	1116(ra) # 80003a04 <ialloc>
    800055b0:	8a2a                	mv	s4,a0
    800055b2:	c539                	beqz	a0,80005600 <create+0xf6>
  ilock(ip);
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	5ec080e7          	jalr	1516(ra) # 80003ba0 <ilock>
  ip->major = major;
    800055bc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055c0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055c4:	4905                	li	s2,1
    800055c6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055ca:	8552                	mv	a0,s4
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	50a080e7          	jalr	1290(ra) # 80003ad6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055d4:	000b059b          	sext.w	a1,s6
    800055d8:	03258b63          	beq	a1,s2,8000560e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800055dc:	004a2603          	lw	a2,4(s4)
    800055e0:	fb040593          	addi	a1,s0,-80
    800055e4:	8526                	mv	a0,s1
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	cae080e7          	jalr	-850(ra) # 80004294 <dirlink>
    800055ee:	06054f63          	bltz	a0,8000566c <create+0x162>
  iunlockput(dp);
    800055f2:	8526                	mv	a0,s1
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	80e080e7          	jalr	-2034(ra) # 80003e02 <iunlockput>
  return ip;
    800055fc:	8ad2                	mv	s5,s4
    800055fe:	b749                	j	80005580 <create+0x76>
    iunlockput(dp);
    80005600:	8526                	mv	a0,s1
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	800080e7          	jalr	-2048(ra) # 80003e02 <iunlockput>
    return 0;
    8000560a:	8ad2                	mv	s5,s4
    8000560c:	bf95                	j	80005580 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000560e:	004a2603          	lw	a2,4(s4)
    80005612:	00003597          	auipc	a1,0x3
    80005616:	0fe58593          	addi	a1,a1,254 # 80008710 <syscalls+0x2c0>
    8000561a:	8552                	mv	a0,s4
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	c78080e7          	jalr	-904(ra) # 80004294 <dirlink>
    80005624:	04054463          	bltz	a0,8000566c <create+0x162>
    80005628:	40d0                	lw	a2,4(s1)
    8000562a:	00003597          	auipc	a1,0x3
    8000562e:	0ee58593          	addi	a1,a1,238 # 80008718 <syscalls+0x2c8>
    80005632:	8552                	mv	a0,s4
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	c60080e7          	jalr	-928(ra) # 80004294 <dirlink>
    8000563c:	02054863          	bltz	a0,8000566c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005640:	004a2603          	lw	a2,4(s4)
    80005644:	fb040593          	addi	a1,s0,-80
    80005648:	8526                	mv	a0,s1
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	c4a080e7          	jalr	-950(ra) # 80004294 <dirlink>
    80005652:	00054d63          	bltz	a0,8000566c <create+0x162>
    dp->nlink++;  // for ".."
    80005656:	04a4d783          	lhu	a5,74(s1)
    8000565a:	2785                	addiw	a5,a5,1
    8000565c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	474080e7          	jalr	1140(ra) # 80003ad6 <iupdate>
    8000566a:	b761                	j	800055f2 <create+0xe8>
  ip->nlink = 0;
    8000566c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005670:	8552                	mv	a0,s4
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	464080e7          	jalr	1124(ra) # 80003ad6 <iupdate>
  iunlockput(ip);
    8000567a:	8552                	mv	a0,s4
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	786080e7          	jalr	1926(ra) # 80003e02 <iunlockput>
  iunlockput(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	77c080e7          	jalr	1916(ra) # 80003e02 <iunlockput>
  return 0;
    8000568e:	bdcd                	j	80005580 <create+0x76>
    return 0;
    80005690:	8aaa                	mv	s5,a0
    80005692:	b5fd                	j	80005580 <create+0x76>

0000000080005694 <sys_dup>:
{
    80005694:	7179                	addi	sp,sp,-48
    80005696:	f406                	sd	ra,40(sp)
    80005698:	f022                	sd	s0,32(sp)
    8000569a:	ec26                	sd	s1,24(sp)
    8000569c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000569e:	fd840613          	addi	a2,s0,-40
    800056a2:	4581                	li	a1,0
    800056a4:	4501                	li	a0,0
    800056a6:	00000097          	auipc	ra,0x0
    800056aa:	dc2080e7          	jalr	-574(ra) # 80005468 <argfd>
    return -1;
    800056ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056b0:	02054363          	bltz	a0,800056d6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056b4:	fd843503          	ld	a0,-40(s0)
    800056b8:	00000097          	auipc	ra,0x0
    800056bc:	e10080e7          	jalr	-496(ra) # 800054c8 <fdalloc>
    800056c0:	84aa                	mv	s1,a0
    return -1;
    800056c2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056c4:	00054963          	bltz	a0,800056d6 <sys_dup+0x42>
  filedup(f);
    800056c8:	fd843503          	ld	a0,-40(s0)
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	310080e7          	jalr	784(ra) # 800049dc <filedup>
  return fd;
    800056d4:	87a6                	mv	a5,s1
}
    800056d6:	853e                	mv	a0,a5
    800056d8:	70a2                	ld	ra,40(sp)
    800056da:	7402                	ld	s0,32(sp)
    800056dc:	64e2                	ld	s1,24(sp)
    800056de:	6145                	addi	sp,sp,48
    800056e0:	8082                	ret

00000000800056e2 <sys_read>:
{
    800056e2:	7179                	addi	sp,sp,-48
    800056e4:	f406                	sd	ra,40(sp)
    800056e6:	f022                	sd	s0,32(sp)
    800056e8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056ea:	fd840593          	addi	a1,s0,-40
    800056ee:	4505                	li	a0,1
    800056f0:	ffffd097          	auipc	ra,0xffffd
    800056f4:	7ac080e7          	jalr	1964(ra) # 80002e9c <argaddr>
  argint(2, &n);
    800056f8:	fe440593          	addi	a1,s0,-28
    800056fc:	4509                	li	a0,2
    800056fe:	ffffd097          	auipc	ra,0xffffd
    80005702:	77e080e7          	jalr	1918(ra) # 80002e7c <argint>
  if(argfd(0, 0, &f) < 0)
    80005706:	fe840613          	addi	a2,s0,-24
    8000570a:	4581                	li	a1,0
    8000570c:	4501                	li	a0,0
    8000570e:	00000097          	auipc	ra,0x0
    80005712:	d5a080e7          	jalr	-678(ra) # 80005468 <argfd>
    80005716:	87aa                	mv	a5,a0
    return -1;
    80005718:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000571a:	0007cc63          	bltz	a5,80005732 <sys_read+0x50>
  return fileread(f, p, n);
    8000571e:	fe442603          	lw	a2,-28(s0)
    80005722:	fd843583          	ld	a1,-40(s0)
    80005726:	fe843503          	ld	a0,-24(s0)
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	43e080e7          	jalr	1086(ra) # 80004b68 <fileread>
}
    80005732:	70a2                	ld	ra,40(sp)
    80005734:	7402                	ld	s0,32(sp)
    80005736:	6145                	addi	sp,sp,48
    80005738:	8082                	ret

000000008000573a <sys_write>:
{
    8000573a:	7179                	addi	sp,sp,-48
    8000573c:	f406                	sd	ra,40(sp)
    8000573e:	f022                	sd	s0,32(sp)
    80005740:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005742:	fd840593          	addi	a1,s0,-40
    80005746:	4505                	li	a0,1
    80005748:	ffffd097          	auipc	ra,0xffffd
    8000574c:	754080e7          	jalr	1876(ra) # 80002e9c <argaddr>
  argint(2, &n);
    80005750:	fe440593          	addi	a1,s0,-28
    80005754:	4509                	li	a0,2
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	726080e7          	jalr	1830(ra) # 80002e7c <argint>
  if(argfd(0, 0, &f) < 0)
    8000575e:	fe840613          	addi	a2,s0,-24
    80005762:	4581                	li	a1,0
    80005764:	4501                	li	a0,0
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	d02080e7          	jalr	-766(ra) # 80005468 <argfd>
    8000576e:	87aa                	mv	a5,a0
    return -1;
    80005770:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005772:	0007cc63          	bltz	a5,8000578a <sys_write+0x50>
  return filewrite(f, p, n);
    80005776:	fe442603          	lw	a2,-28(s0)
    8000577a:	fd843583          	ld	a1,-40(s0)
    8000577e:	fe843503          	ld	a0,-24(s0)
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	4a8080e7          	jalr	1192(ra) # 80004c2a <filewrite>
}
    8000578a:	70a2                	ld	ra,40(sp)
    8000578c:	7402                	ld	s0,32(sp)
    8000578e:	6145                	addi	sp,sp,48
    80005790:	8082                	ret

0000000080005792 <sys_close>:
{
    80005792:	1101                	addi	sp,sp,-32
    80005794:	ec06                	sd	ra,24(sp)
    80005796:	e822                	sd	s0,16(sp)
    80005798:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000579a:	fe040613          	addi	a2,s0,-32
    8000579e:	fec40593          	addi	a1,s0,-20
    800057a2:	4501                	li	a0,0
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	cc4080e7          	jalr	-828(ra) # 80005468 <argfd>
    return -1;
    800057ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057ae:	02054463          	bltz	a0,800057d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057b2:	ffffc097          	auipc	ra,0xffffc
    800057b6:	284080e7          	jalr	644(ra) # 80001a36 <myproc>
    800057ba:	fec42783          	lw	a5,-20(s0)
    800057be:	07e9                	addi	a5,a5,26
    800057c0:	078e                	slli	a5,a5,0x3
    800057c2:	97aa                	add	a5,a5,a0
    800057c4:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800057c8:	fe043503          	ld	a0,-32(s0)
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	262080e7          	jalr	610(ra) # 80004a2e <fileclose>
  return 0;
    800057d4:	4781                	li	a5,0
}
    800057d6:	853e                	mv	a0,a5
    800057d8:	60e2                	ld	ra,24(sp)
    800057da:	6442                	ld	s0,16(sp)
    800057dc:	6105                	addi	sp,sp,32
    800057de:	8082                	ret

00000000800057e0 <sys_fstat>:
{
    800057e0:	1101                	addi	sp,sp,-32
    800057e2:	ec06                	sd	ra,24(sp)
    800057e4:	e822                	sd	s0,16(sp)
    800057e6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057e8:	fe040593          	addi	a1,s0,-32
    800057ec:	4505                	li	a0,1
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	6ae080e7          	jalr	1710(ra) # 80002e9c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057f6:	fe840613          	addi	a2,s0,-24
    800057fa:	4581                	li	a1,0
    800057fc:	4501                	li	a0,0
    800057fe:	00000097          	auipc	ra,0x0
    80005802:	c6a080e7          	jalr	-918(ra) # 80005468 <argfd>
    80005806:	87aa                	mv	a5,a0
    return -1;
    80005808:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000580a:	0007ca63          	bltz	a5,8000581e <sys_fstat+0x3e>
  return filestat(f, st);
    8000580e:	fe043583          	ld	a1,-32(s0)
    80005812:	fe843503          	ld	a0,-24(s0)
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	2e0080e7          	jalr	736(ra) # 80004af6 <filestat>
}
    8000581e:	60e2                	ld	ra,24(sp)
    80005820:	6442                	ld	s0,16(sp)
    80005822:	6105                	addi	sp,sp,32
    80005824:	8082                	ret

0000000080005826 <sys_link>:
{
    80005826:	7169                	addi	sp,sp,-304
    80005828:	f606                	sd	ra,296(sp)
    8000582a:	f222                	sd	s0,288(sp)
    8000582c:	ee26                	sd	s1,280(sp)
    8000582e:	ea4a                	sd	s2,272(sp)
    80005830:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005832:	08000613          	li	a2,128
    80005836:	ed040593          	addi	a1,s0,-304
    8000583a:	4501                	li	a0,0
    8000583c:	ffffd097          	auipc	ra,0xffffd
    80005840:	680080e7          	jalr	1664(ra) # 80002ebc <argstr>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005846:	10054e63          	bltz	a0,80005962 <sys_link+0x13c>
    8000584a:	08000613          	li	a2,128
    8000584e:	f5040593          	addi	a1,s0,-176
    80005852:	4505                	li	a0,1
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	668080e7          	jalr	1640(ra) # 80002ebc <argstr>
    return -1;
    8000585c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000585e:	10054263          	bltz	a0,80005962 <sys_link+0x13c>
  begin_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	d00080e7          	jalr	-768(ra) # 80004562 <begin_op>
  if((ip = namei(old)) == 0){
    8000586a:	ed040513          	addi	a0,s0,-304
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	ad8080e7          	jalr	-1320(ra) # 80004346 <namei>
    80005876:	84aa                	mv	s1,a0
    80005878:	c551                	beqz	a0,80005904 <sys_link+0xde>
  ilock(ip);
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	326080e7          	jalr	806(ra) # 80003ba0 <ilock>
  if(ip->type == T_DIR){
    80005882:	04449703          	lh	a4,68(s1)
    80005886:	4785                	li	a5,1
    80005888:	08f70463          	beq	a4,a5,80005910 <sys_link+0xea>
  ip->nlink++;
    8000588c:	04a4d783          	lhu	a5,74(s1)
    80005890:	2785                	addiw	a5,a5,1
    80005892:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	23e080e7          	jalr	574(ra) # 80003ad6 <iupdate>
  iunlock(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	3c0080e7          	jalr	960(ra) # 80003c62 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058aa:	fd040593          	addi	a1,s0,-48
    800058ae:	f5040513          	addi	a0,s0,-176
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	ab2080e7          	jalr	-1358(ra) # 80004364 <nameiparent>
    800058ba:	892a                	mv	s2,a0
    800058bc:	c935                	beqz	a0,80005930 <sys_link+0x10a>
  ilock(dp);
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	2e2080e7          	jalr	738(ra) # 80003ba0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058c6:	00092703          	lw	a4,0(s2)
    800058ca:	409c                	lw	a5,0(s1)
    800058cc:	04f71d63          	bne	a4,a5,80005926 <sys_link+0x100>
    800058d0:	40d0                	lw	a2,4(s1)
    800058d2:	fd040593          	addi	a1,s0,-48
    800058d6:	854a                	mv	a0,s2
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	9bc080e7          	jalr	-1604(ra) # 80004294 <dirlink>
    800058e0:	04054363          	bltz	a0,80005926 <sys_link+0x100>
  iunlockput(dp);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	51c080e7          	jalr	1308(ra) # 80003e02 <iunlockput>
  iput(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	46a080e7          	jalr	1130(ra) # 80003d5a <iput>
  end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	cea080e7          	jalr	-790(ra) # 800045e2 <end_op>
  return 0;
    80005900:	4781                	li	a5,0
    80005902:	a085                	j	80005962 <sys_link+0x13c>
    end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	cde080e7          	jalr	-802(ra) # 800045e2 <end_op>
    return -1;
    8000590c:	57fd                	li	a5,-1
    8000590e:	a891                	j	80005962 <sys_link+0x13c>
    iunlockput(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	4f0080e7          	jalr	1264(ra) # 80003e02 <iunlockput>
    end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	cc8080e7          	jalr	-824(ra) # 800045e2 <end_op>
    return -1;
    80005922:	57fd                	li	a5,-1
    80005924:	a83d                	j	80005962 <sys_link+0x13c>
    iunlockput(dp);
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	4da080e7          	jalr	1242(ra) # 80003e02 <iunlockput>
  ilock(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	26e080e7          	jalr	622(ra) # 80003ba0 <ilock>
  ip->nlink--;
    8000593a:	04a4d783          	lhu	a5,74(s1)
    8000593e:	37fd                	addiw	a5,a5,-1
    80005940:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	190080e7          	jalr	400(ra) # 80003ad6 <iupdate>
  iunlockput(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	4b2080e7          	jalr	1202(ra) # 80003e02 <iunlockput>
  end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	c8a080e7          	jalr	-886(ra) # 800045e2 <end_op>
  return -1;
    80005960:	57fd                	li	a5,-1
}
    80005962:	853e                	mv	a0,a5
    80005964:	70b2                	ld	ra,296(sp)
    80005966:	7412                	ld	s0,288(sp)
    80005968:	64f2                	ld	s1,280(sp)
    8000596a:	6952                	ld	s2,272(sp)
    8000596c:	6155                	addi	sp,sp,304
    8000596e:	8082                	ret

0000000080005970 <sys_unlink>:
{
    80005970:	7151                	addi	sp,sp,-240
    80005972:	f586                	sd	ra,232(sp)
    80005974:	f1a2                	sd	s0,224(sp)
    80005976:	eda6                	sd	s1,216(sp)
    80005978:	e9ca                	sd	s2,208(sp)
    8000597a:	e5ce                	sd	s3,200(sp)
    8000597c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000597e:	08000613          	li	a2,128
    80005982:	f3040593          	addi	a1,s0,-208
    80005986:	4501                	li	a0,0
    80005988:	ffffd097          	auipc	ra,0xffffd
    8000598c:	534080e7          	jalr	1332(ra) # 80002ebc <argstr>
    80005990:	18054163          	bltz	a0,80005b12 <sys_unlink+0x1a2>
  begin_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	bce080e7          	jalr	-1074(ra) # 80004562 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000599c:	fb040593          	addi	a1,s0,-80
    800059a0:	f3040513          	addi	a0,s0,-208
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	9c0080e7          	jalr	-1600(ra) # 80004364 <nameiparent>
    800059ac:	84aa                	mv	s1,a0
    800059ae:	c979                	beqz	a0,80005a84 <sys_unlink+0x114>
  ilock(dp);
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	1f0080e7          	jalr	496(ra) # 80003ba0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059b8:	00003597          	auipc	a1,0x3
    800059bc:	d5858593          	addi	a1,a1,-680 # 80008710 <syscalls+0x2c0>
    800059c0:	fb040513          	addi	a0,s0,-80
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	6a6080e7          	jalr	1702(ra) # 8000406a <namecmp>
    800059cc:	14050a63          	beqz	a0,80005b20 <sys_unlink+0x1b0>
    800059d0:	00003597          	auipc	a1,0x3
    800059d4:	d4858593          	addi	a1,a1,-696 # 80008718 <syscalls+0x2c8>
    800059d8:	fb040513          	addi	a0,s0,-80
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	68e080e7          	jalr	1678(ra) # 8000406a <namecmp>
    800059e4:	12050e63          	beqz	a0,80005b20 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059e8:	f2c40613          	addi	a2,s0,-212
    800059ec:	fb040593          	addi	a1,s0,-80
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	692080e7          	jalr	1682(ra) # 80004084 <dirlookup>
    800059fa:	892a                	mv	s2,a0
    800059fc:	12050263          	beqz	a0,80005b20 <sys_unlink+0x1b0>
  ilock(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	1a0080e7          	jalr	416(ra) # 80003ba0 <ilock>
  if(ip->nlink < 1)
    80005a08:	04a91783          	lh	a5,74(s2)
    80005a0c:	08f05263          	blez	a5,80005a90 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a10:	04491703          	lh	a4,68(s2)
    80005a14:	4785                	li	a5,1
    80005a16:	08f70563          	beq	a4,a5,80005aa0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a1a:	4641                	li	a2,16
    80005a1c:	4581                	li	a1,0
    80005a1e:	fc040513          	addi	a0,s0,-64
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	2b0080e7          	jalr	688(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2a:	4741                	li	a4,16
    80005a2c:	f2c42683          	lw	a3,-212(s0)
    80005a30:	fc040613          	addi	a2,s0,-64
    80005a34:	4581                	li	a1,0
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	514080e7          	jalr	1300(ra) # 80003f4c <writei>
    80005a40:	47c1                	li	a5,16
    80005a42:	0af51563          	bne	a0,a5,80005aec <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a46:	04491703          	lh	a4,68(s2)
    80005a4a:	4785                	li	a5,1
    80005a4c:	0af70863          	beq	a4,a5,80005afc <sys_unlink+0x18c>
  iunlockput(dp);
    80005a50:	8526                	mv	a0,s1
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	3b0080e7          	jalr	944(ra) # 80003e02 <iunlockput>
  ip->nlink--;
    80005a5a:	04a95783          	lhu	a5,74(s2)
    80005a5e:	37fd                	addiw	a5,a5,-1
    80005a60:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a64:	854a                	mv	a0,s2
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	070080e7          	jalr	112(ra) # 80003ad6 <iupdate>
  iunlockput(ip);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	392080e7          	jalr	914(ra) # 80003e02 <iunlockput>
  end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	b6a080e7          	jalr	-1174(ra) # 800045e2 <end_op>
  return 0;
    80005a80:	4501                	li	a0,0
    80005a82:	a84d                	j	80005b34 <sys_unlink+0x1c4>
    end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	b5e080e7          	jalr	-1186(ra) # 800045e2 <end_op>
    return -1;
    80005a8c:	557d                	li	a0,-1
    80005a8e:	a05d                	j	80005b34 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a90:	00003517          	auipc	a0,0x3
    80005a94:	c9050513          	addi	a0,a0,-880 # 80008720 <syscalls+0x2d0>
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aa0:	04c92703          	lw	a4,76(s2)
    80005aa4:	02000793          	li	a5,32
    80005aa8:	f6e7f9e3          	bgeu	a5,a4,80005a1a <sys_unlink+0xaa>
    80005aac:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ab0:	4741                	li	a4,16
    80005ab2:	86ce                	mv	a3,s3
    80005ab4:	f1840613          	addi	a2,s0,-232
    80005ab8:	4581                	li	a1,0
    80005aba:	854a                	mv	a0,s2
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	398080e7          	jalr	920(ra) # 80003e54 <readi>
    80005ac4:	47c1                	li	a5,16
    80005ac6:	00f51b63          	bne	a0,a5,80005adc <sys_unlink+0x16c>
    if(de.inum != 0)
    80005aca:	f1845783          	lhu	a5,-232(s0)
    80005ace:	e7a1                	bnez	a5,80005b16 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ad0:	29c1                	addiw	s3,s3,16
    80005ad2:	04c92783          	lw	a5,76(s2)
    80005ad6:	fcf9ede3          	bltu	s3,a5,80005ab0 <sys_unlink+0x140>
    80005ada:	b781                	j	80005a1a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005adc:	00003517          	auipc	a0,0x3
    80005ae0:	c5c50513          	addi	a0,a0,-932 # 80008738 <syscalls+0x2e8>
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	a5a080e7          	jalr	-1446(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005aec:	00003517          	auipc	a0,0x3
    80005af0:	c6450513          	addi	a0,a0,-924 # 80008750 <syscalls+0x300>
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	a4a080e7          	jalr	-1462(ra) # 8000053e <panic>
    dp->nlink--;
    80005afc:	04a4d783          	lhu	a5,74(s1)
    80005b00:	37fd                	addiw	a5,a5,-1
    80005b02:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b06:	8526                	mv	a0,s1
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	fce080e7          	jalr	-50(ra) # 80003ad6 <iupdate>
    80005b10:	b781                	j	80005a50 <sys_unlink+0xe0>
    return -1;
    80005b12:	557d                	li	a0,-1
    80005b14:	a005                	j	80005b34 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b16:	854a                	mv	a0,s2
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	2ea080e7          	jalr	746(ra) # 80003e02 <iunlockput>
  iunlockput(dp);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	2e0080e7          	jalr	736(ra) # 80003e02 <iunlockput>
  end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	ab8080e7          	jalr	-1352(ra) # 800045e2 <end_op>
  return -1;
    80005b32:	557d                	li	a0,-1
}
    80005b34:	70ae                	ld	ra,232(sp)
    80005b36:	740e                	ld	s0,224(sp)
    80005b38:	64ee                	ld	s1,216(sp)
    80005b3a:	694e                	ld	s2,208(sp)
    80005b3c:	69ae                	ld	s3,200(sp)
    80005b3e:	616d                	addi	sp,sp,240
    80005b40:	8082                	ret

0000000080005b42 <sys_open>:

uint64
sys_open(void)
{
    80005b42:	7131                	addi	sp,sp,-192
    80005b44:	fd06                	sd	ra,184(sp)
    80005b46:	f922                	sd	s0,176(sp)
    80005b48:	f526                	sd	s1,168(sp)
    80005b4a:	f14a                	sd	s2,160(sp)
    80005b4c:	ed4e                	sd	s3,152(sp)
    80005b4e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b50:	f4c40593          	addi	a1,s0,-180
    80005b54:	4505                	li	a0,1
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	326080e7          	jalr	806(ra) # 80002e7c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b5e:	08000613          	li	a2,128
    80005b62:	f5040593          	addi	a1,s0,-176
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	354080e7          	jalr	852(ra) # 80002ebc <argstr>
    80005b70:	87aa                	mv	a5,a0
    return -1;
    80005b72:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b74:	0a07c963          	bltz	a5,80005c26 <sys_open+0xe4>

  begin_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	9ea080e7          	jalr	-1558(ra) # 80004562 <begin_op>

  if(omode & O_CREATE){
    80005b80:	f4c42783          	lw	a5,-180(s0)
    80005b84:	2007f793          	andi	a5,a5,512
    80005b88:	cfc5                	beqz	a5,80005c40 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b8a:	4681                	li	a3,0
    80005b8c:	4601                	li	a2,0
    80005b8e:	4589                	li	a1,2
    80005b90:	f5040513          	addi	a0,s0,-176
    80005b94:	00000097          	auipc	ra,0x0
    80005b98:	976080e7          	jalr	-1674(ra) # 8000550a <create>
    80005b9c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b9e:	c959                	beqz	a0,80005c34 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ba0:	04449703          	lh	a4,68(s1)
    80005ba4:	478d                	li	a5,3
    80005ba6:	00f71763          	bne	a4,a5,80005bb4 <sys_open+0x72>
    80005baa:	0464d703          	lhu	a4,70(s1)
    80005bae:	47a5                	li	a5,9
    80005bb0:	0ce7ed63          	bltu	a5,a4,80005c8a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	dbe080e7          	jalr	-578(ra) # 80004972 <filealloc>
    80005bbc:	89aa                	mv	s3,a0
    80005bbe:	10050363          	beqz	a0,80005cc4 <sys_open+0x182>
    80005bc2:	00000097          	auipc	ra,0x0
    80005bc6:	906080e7          	jalr	-1786(ra) # 800054c8 <fdalloc>
    80005bca:	892a                	mv	s2,a0
    80005bcc:	0e054763          	bltz	a0,80005cba <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bd0:	04449703          	lh	a4,68(s1)
    80005bd4:	478d                	li	a5,3
    80005bd6:	0cf70563          	beq	a4,a5,80005ca0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bda:	4789                	li	a5,2
    80005bdc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005be0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005be4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005be8:	f4c42783          	lw	a5,-180(s0)
    80005bec:	0017c713          	xori	a4,a5,1
    80005bf0:	8b05                	andi	a4,a4,1
    80005bf2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bf6:	0037f713          	andi	a4,a5,3
    80005bfa:	00e03733          	snez	a4,a4
    80005bfe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c02:	4007f793          	andi	a5,a5,1024
    80005c06:	c791                	beqz	a5,80005c12 <sys_open+0xd0>
    80005c08:	04449703          	lh	a4,68(s1)
    80005c0c:	4789                	li	a5,2
    80005c0e:	0af70063          	beq	a4,a5,80005cae <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c12:	8526                	mv	a0,s1
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	04e080e7          	jalr	78(ra) # 80003c62 <iunlock>
  end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	9c6080e7          	jalr	-1594(ra) # 800045e2 <end_op>

  return fd;
    80005c24:	854a                	mv	a0,s2
}
    80005c26:	70ea                	ld	ra,184(sp)
    80005c28:	744a                	ld	s0,176(sp)
    80005c2a:	74aa                	ld	s1,168(sp)
    80005c2c:	790a                	ld	s2,160(sp)
    80005c2e:	69ea                	ld	s3,152(sp)
    80005c30:	6129                	addi	sp,sp,192
    80005c32:	8082                	ret
      end_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	9ae080e7          	jalr	-1618(ra) # 800045e2 <end_op>
      return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	b7e5                	j	80005c26 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c40:	f5040513          	addi	a0,s0,-176
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	702080e7          	jalr	1794(ra) # 80004346 <namei>
    80005c4c:	84aa                	mv	s1,a0
    80005c4e:	c905                	beqz	a0,80005c7e <sys_open+0x13c>
    ilock(ip);
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	f50080e7          	jalr	-176(ra) # 80003ba0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c58:	04449703          	lh	a4,68(s1)
    80005c5c:	4785                	li	a5,1
    80005c5e:	f4f711e3          	bne	a4,a5,80005ba0 <sys_open+0x5e>
    80005c62:	f4c42783          	lw	a5,-180(s0)
    80005c66:	d7b9                	beqz	a5,80005bb4 <sys_open+0x72>
      iunlockput(ip);
    80005c68:	8526                	mv	a0,s1
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	198080e7          	jalr	408(ra) # 80003e02 <iunlockput>
      end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	970080e7          	jalr	-1680(ra) # 800045e2 <end_op>
      return -1;
    80005c7a:	557d                	li	a0,-1
    80005c7c:	b76d                	j	80005c26 <sys_open+0xe4>
      end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	964080e7          	jalr	-1692(ra) # 800045e2 <end_op>
      return -1;
    80005c86:	557d                	li	a0,-1
    80005c88:	bf79                	j	80005c26 <sys_open+0xe4>
    iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	176080e7          	jalr	374(ra) # 80003e02 <iunlockput>
    end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	94e080e7          	jalr	-1714(ra) # 800045e2 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	b761                	j	80005c26 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ca0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ca4:	04649783          	lh	a5,70(s1)
    80005ca8:	02f99223          	sh	a5,36(s3)
    80005cac:	bf25                	j	80005be4 <sys_open+0xa2>
    itrunc(ip);
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	ffe080e7          	jalr	-2(ra) # 80003cae <itrunc>
    80005cb8:	bfa9                	j	80005c12 <sys_open+0xd0>
      fileclose(f);
    80005cba:	854e                	mv	a0,s3
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	d72080e7          	jalr	-654(ra) # 80004a2e <fileclose>
    iunlockput(ip);
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	13c080e7          	jalr	316(ra) # 80003e02 <iunlockput>
    end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	914080e7          	jalr	-1772(ra) # 800045e2 <end_op>
    return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	b7b9                	j	80005c26 <sys_open+0xe4>

0000000080005cda <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cda:	7175                	addi	sp,sp,-144
    80005cdc:	e506                	sd	ra,136(sp)
    80005cde:	e122                	sd	s0,128(sp)
    80005ce0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	880080e7          	jalr	-1920(ra) # 80004562 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cea:	08000613          	li	a2,128
    80005cee:	f7040593          	addi	a1,s0,-144
    80005cf2:	4501                	li	a0,0
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	1c8080e7          	jalr	456(ra) # 80002ebc <argstr>
    80005cfc:	02054963          	bltz	a0,80005d2e <sys_mkdir+0x54>
    80005d00:	4681                	li	a3,0
    80005d02:	4601                	li	a2,0
    80005d04:	4585                	li	a1,1
    80005d06:	f7040513          	addi	a0,s0,-144
    80005d0a:	00000097          	auipc	ra,0x0
    80005d0e:	800080e7          	jalr	-2048(ra) # 8000550a <create>
    80005d12:	cd11                	beqz	a0,80005d2e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	0ee080e7          	jalr	238(ra) # 80003e02 <iunlockput>
  end_op();
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	8c6080e7          	jalr	-1850(ra) # 800045e2 <end_op>
  return 0;
    80005d24:	4501                	li	a0,0
}
    80005d26:	60aa                	ld	ra,136(sp)
    80005d28:	640a                	ld	s0,128(sp)
    80005d2a:	6149                	addi	sp,sp,144
    80005d2c:	8082                	ret
    end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	8b4080e7          	jalr	-1868(ra) # 800045e2 <end_op>
    return -1;
    80005d36:	557d                	li	a0,-1
    80005d38:	b7fd                	j	80005d26 <sys_mkdir+0x4c>

0000000080005d3a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d3a:	7135                	addi	sp,sp,-160
    80005d3c:	ed06                	sd	ra,152(sp)
    80005d3e:	e922                	sd	s0,144(sp)
    80005d40:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	820080e7          	jalr	-2016(ra) # 80004562 <begin_op>
  argint(1, &major);
    80005d4a:	f6c40593          	addi	a1,s0,-148
    80005d4e:	4505                	li	a0,1
    80005d50:	ffffd097          	auipc	ra,0xffffd
    80005d54:	12c080e7          	jalr	300(ra) # 80002e7c <argint>
  argint(2, &minor);
    80005d58:	f6840593          	addi	a1,s0,-152
    80005d5c:	4509                	li	a0,2
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	11e080e7          	jalr	286(ra) # 80002e7c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d66:	08000613          	li	a2,128
    80005d6a:	f7040593          	addi	a1,s0,-144
    80005d6e:	4501                	li	a0,0
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	14c080e7          	jalr	332(ra) # 80002ebc <argstr>
    80005d78:	02054b63          	bltz	a0,80005dae <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d7c:	f6841683          	lh	a3,-152(s0)
    80005d80:	f6c41603          	lh	a2,-148(s0)
    80005d84:	458d                	li	a1,3
    80005d86:	f7040513          	addi	a0,s0,-144
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	780080e7          	jalr	1920(ra) # 8000550a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d92:	cd11                	beqz	a0,80005dae <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	06e080e7          	jalr	110(ra) # 80003e02 <iunlockput>
  end_op();
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	846080e7          	jalr	-1978(ra) # 800045e2 <end_op>
  return 0;
    80005da4:	4501                	li	a0,0
}
    80005da6:	60ea                	ld	ra,152(sp)
    80005da8:	644a                	ld	s0,144(sp)
    80005daa:	610d                	addi	sp,sp,160
    80005dac:	8082                	ret
    end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	834080e7          	jalr	-1996(ra) # 800045e2 <end_op>
    return -1;
    80005db6:	557d                	li	a0,-1
    80005db8:	b7fd                	j	80005da6 <sys_mknod+0x6c>

0000000080005dba <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dba:	7135                	addi	sp,sp,-160
    80005dbc:	ed06                	sd	ra,152(sp)
    80005dbe:	e922                	sd	s0,144(sp)
    80005dc0:	e526                	sd	s1,136(sp)
    80005dc2:	e14a                	sd	s2,128(sp)
    80005dc4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dc6:	ffffc097          	auipc	ra,0xffffc
    80005dca:	c70080e7          	jalr	-912(ra) # 80001a36 <myproc>
    80005dce:	892a                	mv	s2,a0
  
  begin_op();
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	792080e7          	jalr	1938(ra) # 80004562 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dd8:	08000613          	li	a2,128
    80005ddc:	f6040593          	addi	a1,s0,-160
    80005de0:	4501                	li	a0,0
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	0da080e7          	jalr	218(ra) # 80002ebc <argstr>
    80005dea:	04054b63          	bltz	a0,80005e40 <sys_chdir+0x86>
    80005dee:	f6040513          	addi	a0,s0,-160
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	554080e7          	jalr	1364(ra) # 80004346 <namei>
    80005dfa:	84aa                	mv	s1,a0
    80005dfc:	c131                	beqz	a0,80005e40 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	da2080e7          	jalr	-606(ra) # 80003ba0 <ilock>
  if(ip->type != T_DIR){
    80005e06:	04449703          	lh	a4,68(s1)
    80005e0a:	4785                	li	a5,1
    80005e0c:	04f71063          	bne	a4,a5,80005e4c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e10:	8526                	mv	a0,s1
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	e50080e7          	jalr	-432(ra) # 80003c62 <iunlock>
  iput(p->cwd);
    80005e1a:	15893503          	ld	a0,344(s2)
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	f3c080e7          	jalr	-196(ra) # 80003d5a <iput>
  end_op();
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	7bc080e7          	jalr	1980(ra) # 800045e2 <end_op>
  p->cwd = ip;
    80005e2e:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e32:	4501                	li	a0,0
}
    80005e34:	60ea                	ld	ra,152(sp)
    80005e36:	644a                	ld	s0,144(sp)
    80005e38:	64aa                	ld	s1,136(sp)
    80005e3a:	690a                	ld	s2,128(sp)
    80005e3c:	610d                	addi	sp,sp,160
    80005e3e:	8082                	ret
    end_op();
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	7a2080e7          	jalr	1954(ra) # 800045e2 <end_op>
    return -1;
    80005e48:	557d                	li	a0,-1
    80005e4a:	b7ed                	j	80005e34 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e4c:	8526                	mv	a0,s1
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	fb4080e7          	jalr	-76(ra) # 80003e02 <iunlockput>
    end_op();
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	78c080e7          	jalr	1932(ra) # 800045e2 <end_op>
    return -1;
    80005e5e:	557d                	li	a0,-1
    80005e60:	bfd1                	j	80005e34 <sys_chdir+0x7a>

0000000080005e62 <sys_exec>:

uint64
sys_exec(void)
{
    80005e62:	7145                	addi	sp,sp,-464
    80005e64:	e786                	sd	ra,456(sp)
    80005e66:	e3a2                	sd	s0,448(sp)
    80005e68:	ff26                	sd	s1,440(sp)
    80005e6a:	fb4a                	sd	s2,432(sp)
    80005e6c:	f74e                	sd	s3,424(sp)
    80005e6e:	f352                	sd	s4,416(sp)
    80005e70:	ef56                	sd	s5,408(sp)
    80005e72:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e74:	e3840593          	addi	a1,s0,-456
    80005e78:	4505                	li	a0,1
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	022080e7          	jalr	34(ra) # 80002e9c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e82:	08000613          	li	a2,128
    80005e86:	f4040593          	addi	a1,s0,-192
    80005e8a:	4501                	li	a0,0
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	030080e7          	jalr	48(ra) # 80002ebc <argstr>
    80005e94:	87aa                	mv	a5,a0
    return -1;
    80005e96:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e98:	0c07c263          	bltz	a5,80005f5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e9c:	10000613          	li	a2,256
    80005ea0:	4581                	li	a1,0
    80005ea2:	e4040513          	addi	a0,s0,-448
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	e2c080e7          	jalr	-468(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005eae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005eb2:	89a6                	mv	s3,s1
    80005eb4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eb6:	02000a13          	li	s4,32
    80005eba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ebe:	00391793          	slli	a5,s2,0x3
    80005ec2:	e3040593          	addi	a1,s0,-464
    80005ec6:	e3843503          	ld	a0,-456(s0)
    80005eca:	953e                	add	a0,a0,a5
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	f12080e7          	jalr	-238(ra) # 80002dde <fetchaddr>
    80005ed4:	02054a63          	bltz	a0,80005f08 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ed8:	e3043783          	ld	a5,-464(s0)
    80005edc:	c3b9                	beqz	a5,80005f22 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ede:	ffffb097          	auipc	ra,0xffffb
    80005ee2:	c08080e7          	jalr	-1016(ra) # 80000ae6 <kalloc>
    80005ee6:	85aa                	mv	a1,a0
    80005ee8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eec:	cd11                	beqz	a0,80005f08 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eee:	6605                	lui	a2,0x1
    80005ef0:	e3043503          	ld	a0,-464(s0)
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	f3c080e7          	jalr	-196(ra) # 80002e30 <fetchstr>
    80005efc:	00054663          	bltz	a0,80005f08 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f00:	0905                	addi	s2,s2,1
    80005f02:	09a1                	addi	s3,s3,8
    80005f04:	fb491be3          	bne	s2,s4,80005eba <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f08:	10048913          	addi	s2,s1,256
    80005f0c:	6088                	ld	a0,0(s1)
    80005f0e:	c531                	beqz	a0,80005f5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	ada080e7          	jalr	-1318(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f18:	04a1                	addi	s1,s1,8
    80005f1a:	ff2499e3          	bne	s1,s2,80005f0c <sys_exec+0xaa>
  return -1;
    80005f1e:	557d                	li	a0,-1
    80005f20:	a835                	j	80005f5c <sys_exec+0xfa>
      argv[i] = 0;
    80005f22:	0a8e                	slli	s5,s5,0x3
    80005f24:	fc040793          	addi	a5,s0,-64
    80005f28:	9abe                	add	s5,s5,a5
    80005f2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f2e:	e4040593          	addi	a1,s0,-448
    80005f32:	f4040513          	addi	a0,s0,-192
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	172080e7          	jalr	370(ra) # 800050a8 <exec>
    80005f3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f40:	10048993          	addi	s3,s1,256
    80005f44:	6088                	ld	a0,0(s1)
    80005f46:	c901                	beqz	a0,80005f56 <sys_exec+0xf4>
    kfree(argv[i]);
    80005f48:	ffffb097          	auipc	ra,0xffffb
    80005f4c:	aa2080e7          	jalr	-1374(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f50:	04a1                	addi	s1,s1,8
    80005f52:	ff3499e3          	bne	s1,s3,80005f44 <sys_exec+0xe2>
  return ret;
    80005f56:	854a                	mv	a0,s2
    80005f58:	a011                	j	80005f5c <sys_exec+0xfa>
  return -1;
    80005f5a:	557d                	li	a0,-1
}
    80005f5c:	60be                	ld	ra,456(sp)
    80005f5e:	641e                	ld	s0,448(sp)
    80005f60:	74fa                	ld	s1,440(sp)
    80005f62:	795a                	ld	s2,432(sp)
    80005f64:	79ba                	ld	s3,424(sp)
    80005f66:	7a1a                	ld	s4,416(sp)
    80005f68:	6afa                	ld	s5,408(sp)
    80005f6a:	6179                	addi	sp,sp,464
    80005f6c:	8082                	ret

0000000080005f6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f6e:	7139                	addi	sp,sp,-64
    80005f70:	fc06                	sd	ra,56(sp)
    80005f72:	f822                	sd	s0,48(sp)
    80005f74:	f426                	sd	s1,40(sp)
    80005f76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	abe080e7          	jalr	-1346(ra) # 80001a36 <myproc>
    80005f80:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f82:	fd840593          	addi	a1,s0,-40
    80005f86:	4501                	li	a0,0
    80005f88:	ffffd097          	auipc	ra,0xffffd
    80005f8c:	f14080e7          	jalr	-236(ra) # 80002e9c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f90:	fc840593          	addi	a1,s0,-56
    80005f94:	fd040513          	addi	a0,s0,-48
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	dc6080e7          	jalr	-570(ra) # 80004d5e <pipealloc>
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fa2:	0c054463          	bltz	a0,8000606a <sys_pipe+0xfc>
  fd0 = -1;
    80005fa6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005faa:	fd043503          	ld	a0,-48(s0)
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	51a080e7          	jalr	1306(ra) # 800054c8 <fdalloc>
    80005fb6:	fca42223          	sw	a0,-60(s0)
    80005fba:	08054b63          	bltz	a0,80006050 <sys_pipe+0xe2>
    80005fbe:	fc843503          	ld	a0,-56(s0)
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	506080e7          	jalr	1286(ra) # 800054c8 <fdalloc>
    80005fca:	fca42023          	sw	a0,-64(s0)
    80005fce:	06054863          	bltz	a0,8000603e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd2:	4691                	li	a3,4
    80005fd4:	fc440613          	addi	a2,s0,-60
    80005fd8:	fd843583          	ld	a1,-40(s0)
    80005fdc:	6ca8                	ld	a0,88(s1)
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	68a080e7          	jalr	1674(ra) # 80001668 <copyout>
    80005fe6:	02054063          	bltz	a0,80006006 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fea:	4691                	li	a3,4
    80005fec:	fc040613          	addi	a2,s0,-64
    80005ff0:	fd843583          	ld	a1,-40(s0)
    80005ff4:	0591                	addi	a1,a1,4
    80005ff6:	6ca8                	ld	a0,88(s1)
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	670080e7          	jalr	1648(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006000:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006002:	06055463          	bgez	a0,8000606a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006006:	fc442783          	lw	a5,-60(s0)
    8000600a:	07e9                	addi	a5,a5,26
    8000600c:	078e                	slli	a5,a5,0x3
    8000600e:	97a6                	add	a5,a5,s1
    80006010:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006014:	fc042503          	lw	a0,-64(s0)
    80006018:	0569                	addi	a0,a0,26
    8000601a:	050e                	slli	a0,a0,0x3
    8000601c:	94aa                	add	s1,s1,a0
    8000601e:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006022:	fd043503          	ld	a0,-48(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	a08080e7          	jalr	-1528(ra) # 80004a2e <fileclose>
    fileclose(wf);
    8000602e:	fc843503          	ld	a0,-56(s0)
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	9fc080e7          	jalr	-1540(ra) # 80004a2e <fileclose>
    return -1;
    8000603a:	57fd                	li	a5,-1
    8000603c:	a03d                	j	8000606a <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000603e:	fc442783          	lw	a5,-60(s0)
    80006042:	0007c763          	bltz	a5,80006050 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006046:	07e9                	addi	a5,a5,26
    80006048:	078e                	slli	a5,a5,0x3
    8000604a:	94be                	add	s1,s1,a5
    8000604c:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006050:	fd043503          	ld	a0,-48(s0)
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	9da080e7          	jalr	-1574(ra) # 80004a2e <fileclose>
    fileclose(wf);
    8000605c:	fc843503          	ld	a0,-56(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	9ce080e7          	jalr	-1586(ra) # 80004a2e <fileclose>
    return -1;
    80006068:	57fd                	li	a5,-1
}
    8000606a:	853e                	mv	a0,a5
    8000606c:	70e2                	ld	ra,56(sp)
    8000606e:	7442                	ld	s0,48(sp)
    80006070:	74a2                	ld	s1,40(sp)
    80006072:	6121                	addi	sp,sp,64
    80006074:	8082                	ret
	...

0000000080006080 <kernelvec>:
    80006080:	7111                	addi	sp,sp,-256
    80006082:	e006                	sd	ra,0(sp)
    80006084:	e40a                	sd	sp,8(sp)
    80006086:	e80e                	sd	gp,16(sp)
    80006088:	ec12                	sd	tp,24(sp)
    8000608a:	f016                	sd	t0,32(sp)
    8000608c:	f41a                	sd	t1,40(sp)
    8000608e:	f81e                	sd	t2,48(sp)
    80006090:	fc22                	sd	s0,56(sp)
    80006092:	e0a6                	sd	s1,64(sp)
    80006094:	e4aa                	sd	a0,72(sp)
    80006096:	e8ae                	sd	a1,80(sp)
    80006098:	ecb2                	sd	a2,88(sp)
    8000609a:	f0b6                	sd	a3,96(sp)
    8000609c:	f4ba                	sd	a4,104(sp)
    8000609e:	f8be                	sd	a5,112(sp)
    800060a0:	fcc2                	sd	a6,120(sp)
    800060a2:	e146                	sd	a7,128(sp)
    800060a4:	e54a                	sd	s2,136(sp)
    800060a6:	e94e                	sd	s3,144(sp)
    800060a8:	ed52                	sd	s4,152(sp)
    800060aa:	f156                	sd	s5,160(sp)
    800060ac:	f55a                	sd	s6,168(sp)
    800060ae:	f95e                	sd	s7,176(sp)
    800060b0:	fd62                	sd	s8,184(sp)
    800060b2:	e1e6                	sd	s9,192(sp)
    800060b4:	e5ea                	sd	s10,200(sp)
    800060b6:	e9ee                	sd	s11,208(sp)
    800060b8:	edf2                	sd	t3,216(sp)
    800060ba:	f1f6                	sd	t4,224(sp)
    800060bc:	f5fa                	sd	t5,232(sp)
    800060be:	f9fe                	sd	t6,240(sp)
    800060c0:	bebfc0ef          	jal	ra,80002caa <kerneltrap>
    800060c4:	6082                	ld	ra,0(sp)
    800060c6:	6122                	ld	sp,8(sp)
    800060c8:	61c2                	ld	gp,16(sp)
    800060ca:	7282                	ld	t0,32(sp)
    800060cc:	7322                	ld	t1,40(sp)
    800060ce:	73c2                	ld	t2,48(sp)
    800060d0:	7462                	ld	s0,56(sp)
    800060d2:	6486                	ld	s1,64(sp)
    800060d4:	6526                	ld	a0,72(sp)
    800060d6:	65c6                	ld	a1,80(sp)
    800060d8:	6666                	ld	a2,88(sp)
    800060da:	7686                	ld	a3,96(sp)
    800060dc:	7726                	ld	a4,104(sp)
    800060de:	77c6                	ld	a5,112(sp)
    800060e0:	7866                	ld	a6,120(sp)
    800060e2:	688a                	ld	a7,128(sp)
    800060e4:	692a                	ld	s2,136(sp)
    800060e6:	69ca                	ld	s3,144(sp)
    800060e8:	6a6a                	ld	s4,152(sp)
    800060ea:	7a8a                	ld	s5,160(sp)
    800060ec:	7b2a                	ld	s6,168(sp)
    800060ee:	7bca                	ld	s7,176(sp)
    800060f0:	7c6a                	ld	s8,184(sp)
    800060f2:	6c8e                	ld	s9,192(sp)
    800060f4:	6d2e                	ld	s10,200(sp)
    800060f6:	6dce                	ld	s11,208(sp)
    800060f8:	6e6e                	ld	t3,216(sp)
    800060fa:	7e8e                	ld	t4,224(sp)
    800060fc:	7f2e                	ld	t5,232(sp)
    800060fe:	7fce                	ld	t6,240(sp)
    80006100:	6111                	addi	sp,sp,256
    80006102:	10200073          	sret
    80006106:	00000013          	nop
    8000610a:	00000013          	nop
    8000610e:	0001                	nop

0000000080006110 <timervec>:
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	e10c                	sd	a1,0(a0)
    80006116:	e510                	sd	a2,8(a0)
    80006118:	e914                	sd	a3,16(a0)
    8000611a:	6d0c                	ld	a1,24(a0)
    8000611c:	7110                	ld	a2,32(a0)
    8000611e:	6194                	ld	a3,0(a1)
    80006120:	96b2                	add	a3,a3,a2
    80006122:	e194                	sd	a3,0(a1)
    80006124:	4589                	li	a1,2
    80006126:	14459073          	csrw	sip,a1
    8000612a:	6914                	ld	a3,16(a0)
    8000612c:	6510                	ld	a2,8(a0)
    8000612e:	610c                	ld	a1,0(a0)
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	30200073          	mret
	...

000000008000613a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000613a:	1141                	addi	sp,sp,-16
    8000613c:	e422                	sd	s0,8(sp)
    8000613e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006140:	0c0007b7          	lui	a5,0xc000
    80006144:	4705                	li	a4,1
    80006146:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006148:	c3d8                	sw	a4,4(a5)
}
    8000614a:	6422                	ld	s0,8(sp)
    8000614c:	0141                	addi	sp,sp,16
    8000614e:	8082                	ret

0000000080006150 <plicinithart>:

void
plicinithart(void)
{
    80006150:	1141                	addi	sp,sp,-16
    80006152:	e406                	sd	ra,8(sp)
    80006154:	e022                	sd	s0,0(sp)
    80006156:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	8b2080e7          	jalr	-1870(ra) # 80001a0a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006160:	0085171b          	slliw	a4,a0,0x8
    80006164:	0c0027b7          	lui	a5,0xc002
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	40200713          	li	a4,1026
    8000616e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006172:	00d5151b          	slliw	a0,a0,0xd
    80006176:	0c2017b7          	lui	a5,0xc201
    8000617a:	953e                	add	a0,a0,a5
    8000617c:	00052023          	sw	zero,0(a0)
}
    80006180:	60a2                	ld	ra,8(sp)
    80006182:	6402                	ld	s0,0(sp)
    80006184:	0141                	addi	sp,sp,16
    80006186:	8082                	ret

0000000080006188 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006188:	1141                	addi	sp,sp,-16
    8000618a:	e406                	sd	ra,8(sp)
    8000618c:	e022                	sd	s0,0(sp)
    8000618e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006190:	ffffc097          	auipc	ra,0xffffc
    80006194:	87a080e7          	jalr	-1926(ra) # 80001a0a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006198:	00d5179b          	slliw	a5,a0,0xd
    8000619c:	0c201537          	lui	a0,0xc201
    800061a0:	953e                	add	a0,a0,a5
  return irq;
}
    800061a2:	4148                	lw	a0,4(a0)
    800061a4:	60a2                	ld	ra,8(sp)
    800061a6:	6402                	ld	s0,0(sp)
    800061a8:	0141                	addi	sp,sp,16
    800061aa:	8082                	ret

00000000800061ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ac:	1101                	addi	sp,sp,-32
    800061ae:	ec06                	sd	ra,24(sp)
    800061b0:	e822                	sd	s0,16(sp)
    800061b2:	e426                	sd	s1,8(sp)
    800061b4:	1000                	addi	s0,sp,32
    800061b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	852080e7          	jalr	-1966(ra) # 80001a0a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061c0:	00d5151b          	slliw	a0,a0,0xd
    800061c4:	0c2017b7          	lui	a5,0xc201
    800061c8:	97aa                	add	a5,a5,a0
    800061ca:	c3c4                	sw	s1,4(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret

00000000800061d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061d6:	1141                	addi	sp,sp,-16
    800061d8:	e406                	sd	ra,8(sp)
    800061da:	e022                	sd	s0,0(sp)
    800061dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061de:	479d                	li	a5,7
    800061e0:	04a7cc63          	blt	a5,a0,80006238 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061e4:	00020797          	auipc	a5,0x20
    800061e8:	09c78793          	addi	a5,a5,156 # 80026280 <disk>
    800061ec:	97aa                	add	a5,a5,a0
    800061ee:	0187c783          	lbu	a5,24(a5)
    800061f2:	ebb9                	bnez	a5,80006248 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061f4:	00451613          	slli	a2,a0,0x4
    800061f8:	00020797          	auipc	a5,0x20
    800061fc:	08878793          	addi	a5,a5,136 # 80026280 <disk>
    80006200:	6394                	ld	a3,0(a5)
    80006202:	96b2                	add	a3,a3,a2
    80006204:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006208:	6398                	ld	a4,0(a5)
    8000620a:	9732                	add	a4,a4,a2
    8000620c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006210:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006214:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006218:	953e                	add	a0,a0,a5
    8000621a:	4785                	li	a5,1
    8000621c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006220:	00020517          	auipc	a0,0x20
    80006224:	07850513          	addi	a0,a0,120 # 80026298 <disk+0x18>
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	ffc080e7          	jalr	-4(ra) # 80002224 <wakeup>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret
    panic("free_desc 1");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	52850513          	addi	a0,a0,1320 # 80008760 <syscalls+0x310>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	2fe080e7          	jalr	766(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	52850513          	addi	a0,a0,1320 # 80008770 <syscalls+0x320>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2ee080e7          	jalr	750(ra) # 8000053e <panic>

0000000080006258 <virtio_disk_init>:
{
    80006258:	1101                	addi	sp,sp,-32
    8000625a:	ec06                	sd	ra,24(sp)
    8000625c:	e822                	sd	s0,16(sp)
    8000625e:	e426                	sd	s1,8(sp)
    80006260:	e04a                	sd	s2,0(sp)
    80006262:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006264:	00002597          	auipc	a1,0x2
    80006268:	51c58593          	addi	a1,a1,1308 # 80008780 <syscalls+0x330>
    8000626c:	00020517          	auipc	a0,0x20
    80006270:	13c50513          	addi	a0,a0,316 # 800263a8 <disk+0x128>
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	8d2080e7          	jalr	-1838(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	4398                	lw	a4,0(a5)
    80006282:	2701                	sext.w	a4,a4
    80006284:	747277b7          	lui	a5,0x74727
    80006288:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000628c:	14f71c63          	bne	a4,a5,800063e4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006290:	100017b7          	lui	a5,0x10001
    80006294:	43dc                	lw	a5,4(a5)
    80006296:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006298:	4709                	li	a4,2
    8000629a:	14e79563          	bne	a5,a4,800063e4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	479c                	lw	a5,8(a5)
    800062a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062a6:	12e79f63          	bne	a5,a4,800063e4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062aa:	100017b7          	lui	a5,0x10001
    800062ae:	47d8                	lw	a4,12(a5)
    800062b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062b2:	554d47b7          	lui	a5,0x554d4
    800062b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062ba:	12f71563          	bne	a4,a5,800063e4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062be:	100017b7          	lui	a5,0x10001
    800062c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c6:	4705                	li	a4,1
    800062c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ca:	470d                	li	a4,3
    800062cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062ce:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062d0:	c7ffe737          	lui	a4,0xc7ffe
    800062d4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd839f>
    800062d8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062da:	2701                	sext.w	a4,a4
    800062dc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062de:	472d                	li	a4,11
    800062e0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062e2:	5bbc                	lw	a5,112(a5)
    800062e4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062e8:	8ba1                	andi	a5,a5,8
    800062ea:	10078563          	beqz	a5,800063f4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062f6:	43fc                	lw	a5,68(a5)
    800062f8:	2781                	sext.w	a5,a5
    800062fa:	10079563          	bnez	a5,80006404 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062fe:	100017b7          	lui	a5,0x10001
    80006302:	5bdc                	lw	a5,52(a5)
    80006304:	2781                	sext.w	a5,a5
  if(max == 0)
    80006306:	10078763          	beqz	a5,80006414 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000630a:	471d                	li	a4,7
    8000630c:	10f77c63          	bgeu	a4,a5,80006424 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	7d6080e7          	jalr	2006(ra) # 80000ae6 <kalloc>
    80006318:	00020497          	auipc	s1,0x20
    8000631c:	f6848493          	addi	s1,s1,-152 # 80026280 <disk>
    80006320:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006322:	ffffa097          	auipc	ra,0xffffa
    80006326:	7c4080e7          	jalr	1988(ra) # 80000ae6 <kalloc>
    8000632a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	7ba080e7          	jalr	1978(ra) # 80000ae6 <kalloc>
    80006334:	87aa                	mv	a5,a0
    80006336:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006338:	6088                	ld	a0,0(s1)
    8000633a:	cd6d                	beqz	a0,80006434 <virtio_disk_init+0x1dc>
    8000633c:	00020717          	auipc	a4,0x20
    80006340:	f4c73703          	ld	a4,-180(a4) # 80026288 <disk+0x8>
    80006344:	cb65                	beqz	a4,80006434 <virtio_disk_init+0x1dc>
    80006346:	c7fd                	beqz	a5,80006434 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006348:	6605                	lui	a2,0x1
    8000634a:	4581                	li	a1,0
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	986080e7          	jalr	-1658(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006354:	00020497          	auipc	s1,0x20
    80006358:	f2c48493          	addi	s1,s1,-212 # 80026280 <disk>
    8000635c:	6605                	lui	a2,0x1
    8000635e:	4581                	li	a1,0
    80006360:	6488                	ld	a0,8(s1)
    80006362:	ffffb097          	auipc	ra,0xffffb
    80006366:	970080e7          	jalr	-1680(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000636a:	6605                	lui	a2,0x1
    8000636c:	4581                	li	a1,0
    8000636e:	6888                	ld	a0,16(s1)
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	962080e7          	jalr	-1694(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	4721                	li	a4,8
    8000637e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006380:	4098                	lw	a4,0(s1)
    80006382:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006386:	40d8                	lw	a4,4(s1)
    80006388:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000638c:	6498                	ld	a4,8(s1)
    8000638e:	0007069b          	sext.w	a3,a4
    80006392:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006396:	9701                	srai	a4,a4,0x20
    80006398:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000639c:	6898                	ld	a4,16(s1)
    8000639e:	0007069b          	sext.w	a3,a4
    800063a2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063a6:	9701                	srai	a4,a4,0x20
    800063a8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063ac:	4705                	li	a4,1
    800063ae:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063b0:	00e48c23          	sb	a4,24(s1)
    800063b4:	00e48ca3          	sb	a4,25(s1)
    800063b8:	00e48d23          	sb	a4,26(s1)
    800063bc:	00e48da3          	sb	a4,27(s1)
    800063c0:	00e48e23          	sb	a4,28(s1)
    800063c4:	00e48ea3          	sb	a4,29(s1)
    800063c8:	00e48f23          	sb	a4,30(s1)
    800063cc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063d0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d4:	0727a823          	sw	s2,112(a5)
}
    800063d8:	60e2                	ld	ra,24(sp)
    800063da:	6442                	ld	s0,16(sp)
    800063dc:	64a2                	ld	s1,8(sp)
    800063de:	6902                	ld	s2,0(sp)
    800063e0:	6105                	addi	sp,sp,32
    800063e2:	8082                	ret
    panic("could not find virtio disk");
    800063e4:	00002517          	auipc	a0,0x2
    800063e8:	3ac50513          	addi	a0,a0,940 # 80008790 <syscalls+0x340>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800063f4:	00002517          	auipc	a0,0x2
    800063f8:	3bc50513          	addi	a0,a0,956 # 800087b0 <syscalls+0x360>
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	142080e7          	jalr	322(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006404:	00002517          	auipc	a0,0x2
    80006408:	3cc50513          	addi	a0,a0,972 # 800087d0 <syscalls+0x380>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	132080e7          	jalr	306(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006414:	00002517          	auipc	a0,0x2
    80006418:	3dc50513          	addi	a0,a0,988 # 800087f0 <syscalls+0x3a0>
    8000641c:	ffffa097          	auipc	ra,0xffffa
    80006420:	122080e7          	jalr	290(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006424:	00002517          	auipc	a0,0x2
    80006428:	3ec50513          	addi	a0,a0,1004 # 80008810 <syscalls+0x3c0>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	112080e7          	jalr	274(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006434:	00002517          	auipc	a0,0x2
    80006438:	3fc50513          	addi	a0,a0,1020 # 80008830 <syscalls+0x3e0>
    8000643c:	ffffa097          	auipc	ra,0xffffa
    80006440:	102080e7          	jalr	258(ra) # 8000053e <panic>

0000000080006444 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006444:	7119                	addi	sp,sp,-128
    80006446:	fc86                	sd	ra,120(sp)
    80006448:	f8a2                	sd	s0,112(sp)
    8000644a:	f4a6                	sd	s1,104(sp)
    8000644c:	f0ca                	sd	s2,96(sp)
    8000644e:	ecce                	sd	s3,88(sp)
    80006450:	e8d2                	sd	s4,80(sp)
    80006452:	e4d6                	sd	s5,72(sp)
    80006454:	e0da                	sd	s6,64(sp)
    80006456:	fc5e                	sd	s7,56(sp)
    80006458:	f862                	sd	s8,48(sp)
    8000645a:	f466                	sd	s9,40(sp)
    8000645c:	f06a                	sd	s10,32(sp)
    8000645e:	ec6e                	sd	s11,24(sp)
    80006460:	0100                	addi	s0,sp,128
    80006462:	8aaa                	mv	s5,a0
    80006464:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006466:	00c52d03          	lw	s10,12(a0)
    8000646a:	001d1d1b          	slliw	s10,s10,0x1
    8000646e:	1d02                	slli	s10,s10,0x20
    80006470:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006474:	00020517          	auipc	a0,0x20
    80006478:	f3450513          	addi	a0,a0,-204 # 800263a8 <disk+0x128>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	75a080e7          	jalr	1882(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006484:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006486:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006488:	00020b97          	auipc	s7,0x20
    8000648c:	df8b8b93          	addi	s7,s7,-520 # 80026280 <disk>
  for(int i = 0; i < 3; i++){
    80006490:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006492:	00020c97          	auipc	s9,0x20
    80006496:	f16c8c93          	addi	s9,s9,-234 # 800263a8 <disk+0x128>
    8000649a:	a08d                	j	800064fc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000649c:	00fb8733          	add	a4,s7,a5
    800064a0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064a4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800064a6:	0207c563          	bltz	a5,800064d0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800064aa:	2905                	addiw	s2,s2,1
    800064ac:	0611                	addi	a2,a2,4
    800064ae:	05690c63          	beq	s2,s6,80006506 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800064b2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800064b4:	00020717          	auipc	a4,0x20
    800064b8:	dcc70713          	addi	a4,a4,-564 # 80026280 <disk>
    800064bc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800064be:	01874683          	lbu	a3,24(a4)
    800064c2:	fee9                	bnez	a3,8000649c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800064c4:	2785                	addiw	a5,a5,1
    800064c6:	0705                	addi	a4,a4,1
    800064c8:	fe979be3          	bne	a5,s1,800064be <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800064cc:	57fd                	li	a5,-1
    800064ce:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800064d0:	01205d63          	blez	s2,800064ea <virtio_disk_rw+0xa6>
    800064d4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800064d6:	000a2503          	lw	a0,0(s4)
    800064da:	00000097          	auipc	ra,0x0
    800064de:	cfc080e7          	jalr	-772(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    800064e2:	2d85                	addiw	s11,s11,1
    800064e4:	0a11                	addi	s4,s4,4
    800064e6:	ffb918e3          	bne	s2,s11,800064d6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064ea:	85e6                	mv	a1,s9
    800064ec:	00020517          	auipc	a0,0x20
    800064f0:	dac50513          	addi	a0,a0,-596 # 80026298 <disk+0x18>
    800064f4:	ffffc097          	auipc	ra,0xffffc
    800064f8:	ccc080e7          	jalr	-820(ra) # 800021c0 <sleep>
  for(int i = 0; i < 3; i++){
    800064fc:	f8040a13          	addi	s4,s0,-128
{
    80006500:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006502:	894e                	mv	s2,s3
    80006504:	b77d                	j	800064b2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006506:	f8042583          	lw	a1,-128(s0)
    8000650a:	00a58793          	addi	a5,a1,10
    8000650e:	0792                	slli	a5,a5,0x4

  if(write)
    80006510:	00020617          	auipc	a2,0x20
    80006514:	d7060613          	addi	a2,a2,-656 # 80026280 <disk>
    80006518:	00f60733          	add	a4,a2,a5
    8000651c:	018036b3          	snez	a3,s8
    80006520:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006522:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006526:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000652a:	f6078693          	addi	a3,a5,-160
    8000652e:	6218                	ld	a4,0(a2)
    80006530:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006532:	00878513          	addi	a0,a5,8
    80006536:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006538:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000653a:	6208                	ld	a0,0(a2)
    8000653c:	96aa                	add	a3,a3,a0
    8000653e:	4741                	li	a4,16
    80006540:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006542:	4705                	li	a4,1
    80006544:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006548:	f8442703          	lw	a4,-124(s0)
    8000654c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006550:	0712                	slli	a4,a4,0x4
    80006552:	953a                	add	a0,a0,a4
    80006554:	058a8693          	addi	a3,s5,88
    80006558:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000655a:	6208                	ld	a0,0(a2)
    8000655c:	972a                	add	a4,a4,a0
    8000655e:	40000693          	li	a3,1024
    80006562:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006564:	001c3c13          	seqz	s8,s8
    80006568:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000656a:	001c6c13          	ori	s8,s8,1
    8000656e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006572:	f8842603          	lw	a2,-120(s0)
    80006576:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000657a:	00020697          	auipc	a3,0x20
    8000657e:	d0668693          	addi	a3,a3,-762 # 80026280 <disk>
    80006582:	00258713          	addi	a4,a1,2
    80006586:	0712                	slli	a4,a4,0x4
    80006588:	9736                	add	a4,a4,a3
    8000658a:	587d                	li	a6,-1
    8000658c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006590:	0612                	slli	a2,a2,0x4
    80006592:	9532                	add	a0,a0,a2
    80006594:	f9078793          	addi	a5,a5,-112
    80006598:	97b6                	add	a5,a5,a3
    8000659a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000659c:	629c                	ld	a5,0(a3)
    8000659e:	97b2                	add	a5,a5,a2
    800065a0:	4605                	li	a2,1
    800065a2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065a4:	4509                	li	a0,2
    800065a6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800065aa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065ae:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800065b2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065b6:	6698                	ld	a4,8(a3)
    800065b8:	00275783          	lhu	a5,2(a4)
    800065bc:	8b9d                	andi	a5,a5,7
    800065be:	0786                	slli	a5,a5,0x1
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065c6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ca:	6698                	ld	a4,8(a3)
    800065cc:	00275783          	lhu	a5,2(a4)
    800065d0:	2785                	addiw	a5,a5,1
    800065d2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065d6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065da:	100017b7          	lui	a5,0x10001
    800065de:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065e2:	004aa783          	lw	a5,4(s5)
    800065e6:	02c79163          	bne	a5,a2,80006608 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065ea:	00020917          	auipc	s2,0x20
    800065ee:	dbe90913          	addi	s2,s2,-578 # 800263a8 <disk+0x128>
  while(b->disk == 1) {
    800065f2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065f4:	85ca                	mv	a1,s2
    800065f6:	8556                	mv	a0,s5
    800065f8:	ffffc097          	auipc	ra,0xffffc
    800065fc:	bc8080e7          	jalr	-1080(ra) # 800021c0 <sleep>
  while(b->disk == 1) {
    80006600:	004aa783          	lw	a5,4(s5)
    80006604:	fe9788e3          	beq	a5,s1,800065f4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006608:	f8042903          	lw	s2,-128(s0)
    8000660c:	00290793          	addi	a5,s2,2
    80006610:	00479713          	slli	a4,a5,0x4
    80006614:	00020797          	auipc	a5,0x20
    80006618:	c6c78793          	addi	a5,a5,-916 # 80026280 <disk>
    8000661c:	97ba                	add	a5,a5,a4
    8000661e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006622:	00020997          	auipc	s3,0x20
    80006626:	c5e98993          	addi	s3,s3,-930 # 80026280 <disk>
    8000662a:	00491713          	slli	a4,s2,0x4
    8000662e:	0009b783          	ld	a5,0(s3)
    80006632:	97ba                	add	a5,a5,a4
    80006634:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006638:	854a                	mv	a0,s2
    8000663a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000663e:	00000097          	auipc	ra,0x0
    80006642:	b98080e7          	jalr	-1128(ra) # 800061d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006646:	8885                	andi	s1,s1,1
    80006648:	f0ed                	bnez	s1,8000662a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000664a:	00020517          	auipc	a0,0x20
    8000664e:	d5e50513          	addi	a0,a0,-674 # 800263a8 <disk+0x128>
    80006652:	ffffa097          	auipc	ra,0xffffa
    80006656:	638080e7          	jalr	1592(ra) # 80000c8a <release>
}
    8000665a:	70e6                	ld	ra,120(sp)
    8000665c:	7446                	ld	s0,112(sp)
    8000665e:	74a6                	ld	s1,104(sp)
    80006660:	7906                	ld	s2,96(sp)
    80006662:	69e6                	ld	s3,88(sp)
    80006664:	6a46                	ld	s4,80(sp)
    80006666:	6aa6                	ld	s5,72(sp)
    80006668:	6b06                	ld	s6,64(sp)
    8000666a:	7be2                	ld	s7,56(sp)
    8000666c:	7c42                	ld	s8,48(sp)
    8000666e:	7ca2                	ld	s9,40(sp)
    80006670:	7d02                	ld	s10,32(sp)
    80006672:	6de2                	ld	s11,24(sp)
    80006674:	6109                	addi	sp,sp,128
    80006676:	8082                	ret

0000000080006678 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006678:	1101                	addi	sp,sp,-32
    8000667a:	ec06                	sd	ra,24(sp)
    8000667c:	e822                	sd	s0,16(sp)
    8000667e:	e426                	sd	s1,8(sp)
    80006680:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006682:	00020497          	auipc	s1,0x20
    80006686:	bfe48493          	addi	s1,s1,-1026 # 80026280 <disk>
    8000668a:	00020517          	auipc	a0,0x20
    8000668e:	d1e50513          	addi	a0,a0,-738 # 800263a8 <disk+0x128>
    80006692:	ffffa097          	auipc	ra,0xffffa
    80006696:	544080e7          	jalr	1348(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000669a:	10001737          	lui	a4,0x10001
    8000669e:	533c                	lw	a5,96(a4)
    800066a0:	8b8d                	andi	a5,a5,3
    800066a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066a8:	689c                	ld	a5,16(s1)
    800066aa:	0204d703          	lhu	a4,32(s1)
    800066ae:	0027d783          	lhu	a5,2(a5)
    800066b2:	04f70863          	beq	a4,a5,80006702 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066b6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066ba:	6898                	ld	a4,16(s1)
    800066bc:	0204d783          	lhu	a5,32(s1)
    800066c0:	8b9d                	andi	a5,a5,7
    800066c2:	078e                	slli	a5,a5,0x3
    800066c4:	97ba                	add	a5,a5,a4
    800066c6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066c8:	00278713          	addi	a4,a5,2
    800066cc:	0712                	slli	a4,a4,0x4
    800066ce:	9726                	add	a4,a4,s1
    800066d0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066d4:	e721                	bnez	a4,8000671c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066d6:	0789                	addi	a5,a5,2
    800066d8:	0792                	slli	a5,a5,0x4
    800066da:	97a6                	add	a5,a5,s1
    800066dc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066de:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066e2:	ffffc097          	auipc	ra,0xffffc
    800066e6:	b42080e7          	jalr	-1214(ra) # 80002224 <wakeup>

    disk.used_idx += 1;
    800066ea:	0204d783          	lhu	a5,32(s1)
    800066ee:	2785                	addiw	a5,a5,1
    800066f0:	17c2                	slli	a5,a5,0x30
    800066f2:	93c1                	srli	a5,a5,0x30
    800066f4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066f8:	6898                	ld	a4,16(s1)
    800066fa:	00275703          	lhu	a4,2(a4)
    800066fe:	faf71ce3          	bne	a4,a5,800066b6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006702:	00020517          	auipc	a0,0x20
    80006706:	ca650513          	addi	a0,a0,-858 # 800263a8 <disk+0x128>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
}
    80006712:	60e2                	ld	ra,24(sp)
    80006714:	6442                	ld	s0,16(sp)
    80006716:	64a2                	ld	s1,8(sp)
    80006718:	6105                	addi	sp,sp,32
    8000671a:	8082                	ret
      panic("virtio_disk_intr status");
    8000671c:	00002517          	auipc	a0,0x2
    80006720:	12c50513          	addi	a0,a0,300 # 80008848 <syscalls+0x3f8>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	e1a080e7          	jalr	-486(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
