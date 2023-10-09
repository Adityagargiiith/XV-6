
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	addi	sp,sp,-1472 # 80008a40 <stack0>
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
    80000056:	8ae70713          	addi	a4,a4,-1874 # 80008900 <timer_scratch>
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
    80000068:	14c78793          	addi	a5,a5,332 # 800061b0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda06f>
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
    80000130:	5d0080e7          	jalr	1488(ra) # 800026fc <either_copyin>
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
    8000018e:	8b650513          	addi	a0,a0,-1866 # 80010a40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8a648493          	addi	s1,s1,-1882 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	93690913          	addi	s2,s2,-1738 # 80010ad8 <cons+0x98>
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
    800001c4:	8d2080e7          	jalr	-1838(ra) # 80001a92 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	37e080e7          	jalr	894(ra) # 80002546 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	0bc080e7          	jalr	188(ra) # 80002292 <sleep>
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
    80000216:	494080e7          	jalr	1172(ra) # 800026a6 <either_copyout>
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
    8000022a:	81a50513          	addi	a0,a0,-2022 # 80010a40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	80450513          	addi	a0,a0,-2044 # 80010a40 <cons>
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
    80000276:	86f72323          	sw	a5,-1946(a4) # 80010ad8 <cons+0x98>
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
    800002d0:	77450513          	addi	a0,a0,1908 # 80010a40 <cons>
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
    800002f6:	460080e7          	jalr	1120(ra) # 80002752 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	74650513          	addi	a0,a0,1862 # 80010a40 <cons>
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
    80000322:	72270713          	addi	a4,a4,1826 # 80010a40 <cons>
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
    8000034c:	6f878793          	addi	a5,a5,1784 # 80010a40 <cons>
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
    8000037a:	7627a783          	lw	a5,1890(a5) # 80010ad8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6b670713          	addi	a4,a4,1718 # 80010a40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6a648493          	addi	s1,s1,1702 # 80010a40 <cons>
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
    800003da:	66a70713          	addi	a4,a4,1642 # 80010a40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72a23          	sw	a5,1780(a4) # 80010ae0 <cons+0xa0>
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
    80000416:	62e78793          	addi	a5,a5,1582 # 80010a40 <cons>
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
    8000043a:	6ac7a323          	sw	a2,1702(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	69a50513          	addi	a0,a0,1690 # 80010ad8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	eb0080e7          	jalr	-336(ra) # 800022f6 <wakeup>
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
    80000464:	5e050513          	addi	a0,a0,1504 # 80010a40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	18078793          	addi	a5,a5,384 # 800235f8 <devsw>
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
    8000054e:	5a07ab23          	sw	zero,1462(a5) # 80010b00 <pr+0x18>
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
    80000582:	34f72123          	sw	a5,834(a4) # 800088c0 <panicked>
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
    800005be:	546dad83          	lw	s11,1350(s11) # 80010b00 <pr+0x18>
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
    800005fc:	4f050513          	addi	a0,a0,1264 # 80010ae8 <pr>
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
    8000075a:	39250513          	addi	a0,a0,914 # 80010ae8 <pr>
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
    80000776:	37648493          	addi	s1,s1,886 # 80010ae8 <pr>
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
    800007d6:	33650513          	addi	a0,a0,822 # 80010b08 <uart_tx_lock>
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
    80000802:	0c27a783          	lw	a5,194(a5) # 800088c0 <panicked>
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
    8000083a:	0927b783          	ld	a5,146(a5) # 800088c8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	09273703          	ld	a4,146(a4) # 800088d0 <uart_tx_w>
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
    80000864:	2a8a0a13          	addi	s4,s4,680 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	06048493          	addi	s1,s1,96 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	06098993          	addi	s3,s3,96 # 800088d0 <uart_tx_w>
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
    80000896:	a64080e7          	jalr	-1436(ra) # 800022f6 <wakeup>
    
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
    800008d2:	23a50513          	addi	a0,a0,570 # 80010b08 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fe27a783          	lw	a5,-30(a5) # 800088c0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fe873703          	ld	a4,-24(a4) # 800088d0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fd87b783          	ld	a5,-40(a5) # 800088c8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	20c98993          	addi	s3,s3,524 # 80010b08 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fc448493          	addi	s1,s1,-60 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fc490913          	addi	s2,s2,-60 # 800088d0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	976080e7          	jalr	-1674(ra) # 80002292 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1d648493          	addi	s1,s1,470 # 80010b08 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7b523          	sd	a4,-118(a5) # 800088d0 <uart_tx_w>
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
    800009c0:	14c48493          	addi	s1,s1,332 # 80010b08 <uart_tx_lock>
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
    800009fe:	00024797          	auipc	a5,0x24
    80000a02:	d9278793          	addi	a5,a5,-622 # 80024790 <end>
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
    80000a22:	12290913          	addi	s2,s2,290 # 80010b40 <kmem>
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
    80000abe:	08650513          	addi	a0,a0,134 # 80010b40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	cc250513          	addi	a0,a0,-830 # 80024790 <end>
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
    80000af4:	05048493          	addi	s1,s1,80 # 80010b40 <kmem>
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
    80000b0c:	03850513          	addi	a0,a0,56 # 80010b40 <kmem>
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
    80000b38:	00c50513          	addi	a0,a0,12 # 80010b40 <kmem>
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
    80000b74:	f06080e7          	jalr	-250(ra) # 80001a76 <mycpu>
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
    80000ba6:	ed4080e7          	jalr	-300(ra) # 80001a76 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ec8080e7          	jalr	-312(ra) # 80001a76 <mycpu>
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
    80000bca:	eb0080e7          	jalr	-336(ra) # 80001a76 <mycpu>
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
    80000c0a:	e70080e7          	jalr	-400(ra) # 80001a76 <mycpu>
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
    80000c36:	e44080e7          	jalr	-444(ra) # 80001a76 <mycpu>
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
    80000e84:	be6080e7          	jalr	-1050(ra) # 80001a66 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a5070713          	addi	a4,a4,-1456 # 800088d8 <started>
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
    80000ea0:	bca080e7          	jalr	-1078(ra) # 80001a66 <cpuid>
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
    80000ec2:	b7e080e7          	jalr	-1154(ra) # 80002a3c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	32a080e7          	jalr	810(ra) # 800061f0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	108080e7          	jalr	264(ra) # 80001fd6 <scheduler>
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
    80000f32:	a84080e7          	jalr	-1404(ra) # 800019b2 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	ade080e7          	jalr	-1314(ra) # 80002a14 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	afe080e7          	jalr	-1282(ra) # 80002a3c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	294080e7          	jalr	660(ra) # 800061da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	2a2080e7          	jalr	674(ra) # 800061f0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	44c080e7          	jalr	1100(ra) # 800033a2 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	af0080e7          	jalr	-1296(ra) # 80003a4e <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a8e080e7          	jalr	-1394(ra) # 800049f4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	38a080e7          	jalr	906(ra) # 800062f8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	e42080e7          	jalr	-446(ra) # 80001db8 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72a23          	sw	a5,-1708(a4) # 800088d8 <started>
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
    80000f9c:	9487b783          	ld	a5,-1720(a5) # 800088e0 <kernel_pagetable>
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
    80001232:	6ee080e7          	jalr	1774(ra) # 8000191c <proc_mapstacks>
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
    80001258:	68a7b623          	sd	a0,1676(a5) # 800088e0 <kernel_pagetable>
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

0000000080001836 <popfront>:
// #define MLFQ
#define tickforage 35

queue mlfq[4];
void popfront(queue *a)
{
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
    for (int i = 0; i < a->end - 1; i++)
    8000183c:	20052703          	lw	a4,512(a0)
    80001840:	fff7061b          	addiw	a2,a4,-1
    80001844:	0006079b          	sext.w	a5,a2
    80001848:	cf91                	beqz	a5,80001864 <popfront+0x2e>
    8000184a:	87aa                	mv	a5,a0
    8000184c:	3779                	addiw	a4,a4,-2
    8000184e:	1702                	slli	a4,a4,0x20
    80001850:	9301                	srli	a4,a4,0x20
    80001852:	070e                	slli	a4,a4,0x3
    80001854:	00850693          	addi	a3,a0,8
    80001858:	9736                	add	a4,a4,a3
    {
        a->n[i] = a->n[i + 1];
    8000185a:	6794                	ld	a3,8(a5)
    8000185c:	e394                	sd	a3,0(a5)
    for (int i = 0; i < a->end - 1; i++)
    8000185e:	07a1                	addi	a5,a5,8
    80001860:	fee79de3          	bne	a5,a4,8000185a <popfront+0x24>
    }
    a->end--;
    80001864:	20c52023          	sw	a2,512(a0)
    return;
}
    80001868:	6422                	ld	s0,8(sp)
    8000186a:	0141                	addi	sp,sp,16
    8000186c:	8082                	ret

000000008000186e <pushback>:
void pushback(queue *a, struct proc *x)
{
    if (a->end == NPROC)
    8000186e:	20052783          	lw	a5,512(a0)
    80001872:	04000713          	li	a4,64
    80001876:	00e78c63          	beq	a5,a4,8000188e <pushback+0x20>
    {
        panic("Error!");
        return;
    }
    a->n[a->end] = x;
    8000187a:	02079713          	slli	a4,a5,0x20
    8000187e:	9301                	srli	a4,a4,0x20
    80001880:	070e                	slli	a4,a4,0x3
    80001882:	972a                	add	a4,a4,a0
    80001884:	e30c                	sd	a1,0(a4)
    a->end++;
    80001886:	2785                	addiw	a5,a5,1
    80001888:	20f52023          	sw	a5,512(a0)
    8000188c:	8082                	ret
{
    8000188e:	1141                	addi	sp,sp,-16
    80001890:	e406                	sd	ra,8(sp)
    80001892:	e022                	sd	s0,0(sp)
    80001894:	0800                	addi	s0,sp,16
        panic("Error!");
    80001896:	00007517          	auipc	a0,0x7
    8000189a:	94250513          	addi	a0,a0,-1726 # 800081d8 <digits+0x198>
    8000189e:	fffff097          	auipc	ra,0xfffff
    800018a2:	ca0080e7          	jalr	-864(ra) # 8000053e <panic>

00000000800018a6 <front>:
    return;
}
struct proc *front(queue *a)
{
    800018a6:	1141                	addi	sp,sp,-16
    800018a8:	e422                	sd	s0,8(sp)
    800018aa:	0800                	addi	s0,sp,16
    if (a->end == 0)
    800018ac:	20052783          	lw	a5,512(a0)
    800018b0:	c789                	beqz	a5,800018ba <front+0x14>
    {
        return 0;
    }
    return a->n[0];
    800018b2:	6108                	ld	a0,0(a0)
}
    800018b4:	6422                	ld	s0,8(sp)
    800018b6:	0141                	addi	sp,sp,16
    800018b8:	8082                	ret
        return 0;
    800018ba:	4501                	li	a0,0
    800018bc:	bfe5                	j	800018b4 <front+0xe>

00000000800018be <size>:
int size(queue *a)
{
    800018be:	1141                	addi	sp,sp,-16
    800018c0:	e422                	sd	s0,8(sp)
    800018c2:	0800                	addi	s0,sp,16
    return a->end;
}
    800018c4:	20052503          	lw	a0,512(a0)
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <remove>:
void remove (queue *a, uint pid)
{
    800018ce:	1141                	addi	sp,sp,-16
    800018d0:	e422                	sd	s0,8(sp)
    800018d2:	0800                	addi	s0,sp,16
    int flag = 0;
    for (int i = 0; i < a->end; i++)
    800018d4:	20052e03          	lw	t3,512(a0)
    800018d8:	020e0c63          	beqz	t3,80001910 <remove+0x42>
    800018dc:	87aa                	mv	a5,a0
    800018de:	000e031b          	sext.w	t1,t3
    800018e2:	4701                	li	a4,0
    int flag = 0;
    800018e4:	4881                	li	a7,0
    {
        if (pid == a->n[i]->pid)
        {
            flag = 1;
        }
        if (flag == 1 && i != NPROC)
    800018e6:	04000e93          	li	t4,64
    800018ea:	4805                	li	a6,1
    800018ec:	a811                	j	80001900 <remove+0x32>
    800018ee:	88c2                	mv	a7,a6
    800018f0:	01d70463          	beq	a4,t4,800018f8 <remove+0x2a>
        {
            a->n[i] = a->n[i + 1];
    800018f4:	6614                	ld	a3,8(a2)
    800018f6:	e214                	sd	a3,0(a2)
    for (int i = 0; i < a->end; i++)
    800018f8:	2705                	addiw	a4,a4,1
    800018fa:	07a1                	addi	a5,a5,8
    800018fc:	00670a63          	beq	a4,t1,80001910 <remove+0x42>
        if (pid == a->n[i]->pid)
    80001900:	863e                	mv	a2,a5
    80001902:	6394                	ld	a3,0(a5)
    80001904:	5a94                	lw	a3,48(a3)
    80001906:	feb684e3          	beq	a3,a1,800018ee <remove+0x20>
        if (flag == 1 && i != NPROC)
    8000190a:	ff0897e3          	bne	a7,a6,800018f8 <remove+0x2a>
    8000190e:	b7c5                	j	800018ee <remove+0x20>
        }
    }
    a->end--;
    80001910:	3e7d                	addiw	t3,t3,-1
    80001912:	21c52023          	sw	t3,512(a0)
    return;
}
    80001916:	6422                	ld	s0,8(sp)
    80001918:	0141                	addi	sp,sp,16
    8000191a:	8082                	ret

000000008000191c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000191c:	7139                	addi	sp,sp,-64
    8000191e:	fc06                	sd	ra,56(sp)
    80001920:	f822                	sd	s0,48(sp)
    80001922:	f426                	sd	s1,40(sp)
    80001924:	f04a                	sd	s2,32(sp)
    80001926:	ec4e                	sd	s3,24(sp)
    80001928:	e852                	sd	s4,16(sp)
    8000192a:	e456                	sd	s5,8(sp)
    8000192c:	e05a                	sd	s6,0(sp)
    8000192e:	0080                	addi	s0,sp,64
    80001930:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	0000f497          	auipc	s1,0xf
    80001936:	65e48493          	addi	s1,s1,1630 # 80010f90 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000193a:	8b26                	mv	s6,s1
    8000193c:	00006a97          	auipc	s5,0x6
    80001940:	6c4a8a93          	addi	s5,s5,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00017a17          	auipc	s4,0x17
    80001950:	244a0a13          	addi	s4,s4,580 # 80018b90 <mlfq>
    char *pa = kalloc();
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	192080e7          	jalr	402(ra) # 80000ae6 <kalloc>
    8000195c:	862a                	mv	a2,a0
    if (pa == 0)
    8000195e:	c131                	beqz	a0,800019a2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001960:	416485b3          	sub	a1,s1,s6
    80001964:	8591                	srai	a1,a1,0x4
    80001966:	000ab783          	ld	a5,0(s5)
    8000196a:	02f585b3          	mul	a1,a1,a5
    8000196e:	2585                	addiw	a1,a1,1
    80001970:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001974:	4719                	li	a4,6
    80001976:	6685                	lui	a3,0x1
    80001978:	40b905b3          	sub	a1,s2,a1
    8000197c:	854e                	mv	a0,s3
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	7c0080e7          	jalr	1984(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001986:	1f048493          	addi	s1,s1,496
    8000198a:	fd4495e3          	bne	s1,s4,80001954 <proc_mapstacks+0x38>
  }
}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret
      panic("kalloc");
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	83e50513          	addi	a0,a0,-1986 # 800081e0 <digits+0x1a0>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>

00000000800019b2 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800019b2:	7139                	addi	sp,sp,-64
    800019b4:	fc06                	sd	ra,56(sp)
    800019b6:	f822                	sd	s0,48(sp)
    800019b8:	f426                	sd	s1,40(sp)
    800019ba:	f04a                	sd	s2,32(sp)
    800019bc:	ec4e                	sd	s3,24(sp)
    800019be:	e852                	sd	s4,16(sp)
    800019c0:	e456                	sd	s5,8(sp)
    800019c2:	e05a                	sd	s6,0(sp)
    800019c4:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019c6:	00007597          	auipc	a1,0x7
    800019ca:	82258593          	addi	a1,a1,-2014 # 800081e8 <digits+0x1a8>
    800019ce:	0000f517          	auipc	a0,0xf
    800019d2:	19250513          	addi	a0,a0,402 # 80010b60 <pid_lock>
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	170080e7          	jalr	368(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019de:	00007597          	auipc	a1,0x7
    800019e2:	81258593          	addi	a1,a1,-2030 # 800081f0 <digits+0x1b0>
    800019e6:	0000f517          	auipc	a0,0xf
    800019ea:	19250513          	addi	a0,a0,402 # 80010b78 <wait_lock>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	158080e7          	jalr	344(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019f6:	0000f497          	auipc	s1,0xf
    800019fa:	59a48493          	addi	s1,s1,1434 # 80010f90 <proc>
  {
    initlock(&p->lock, "proc");
    800019fe:	00007b17          	auipc	s6,0x7
    80001a02:	802b0b13          	addi	s6,s6,-2046 # 80008200 <digits+0x1c0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a06:	8aa6                	mv	s5,s1
    80001a08:	00006a17          	auipc	s4,0x6
    80001a0c:	5f8a0a13          	addi	s4,s4,1528 # 80008000 <etext>
    80001a10:	04000937          	lui	s2,0x4000
    80001a14:	197d                	addi	s2,s2,-1
    80001a16:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a18:	00017997          	auipc	s3,0x17
    80001a1c:	17898993          	addi	s3,s3,376 # 80018b90 <mlfq>
    initlock(&p->lock, "proc");
    80001a20:	85da                	mv	a1,s6
    80001a22:	8526                	mv	a0,s1
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	122080e7          	jalr	290(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001a2c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a30:	415487b3          	sub	a5,s1,s5
    80001a34:	8791                	srai	a5,a5,0x4
    80001a36:	000a3703          	ld	a4,0(s4)
    80001a3a:	02e787b3          	mul	a5,a5,a4
    80001a3e:	2785                	addiw	a5,a5,1
    80001a40:	00d7979b          	slliw	a5,a5,0xd
    80001a44:	40f907b3          	sub	a5,s2,a5
    80001a48:	e4bc                	sd	a5,72(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a4a:	1f048493          	addi	s1,s1,496
    80001a4e:	fd3499e3          	bne	s1,s3,80001a20 <procinit+0x6e>
  }
}
    80001a52:	70e2                	ld	ra,56(sp)
    80001a54:	7442                	ld	s0,48(sp)
    80001a56:	74a2                	ld	s1,40(sp)
    80001a58:	7902                	ld	s2,32(sp)
    80001a5a:	69e2                	ld	s3,24(sp)
    80001a5c:	6a42                	ld	s4,16(sp)
    80001a5e:	6aa2                	ld	s5,8(sp)
    80001a60:	6b02                	ld	s6,0(sp)
    80001a62:	6121                	addi	sp,sp,64
    80001a64:	8082                	ret

0000000080001a66 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a66:	1141                	addi	sp,sp,-16
    80001a68:	e422                	sd	s0,8(sp)
    80001a6a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a6c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a6e:	2501                	sext.w	a0,a0
    80001a70:	6422                	ld	s0,8(sp)
    80001a72:	0141                	addi	sp,sp,16
    80001a74:	8082                	ret

0000000080001a76 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e422                	sd	s0,8(sp)
    80001a7a:	0800                	addi	s0,sp,16
    80001a7c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a7e:	2781                	sext.w	a5,a5
    80001a80:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a82:	0000f517          	auipc	a0,0xf
    80001a86:	10e50513          	addi	a0,a0,270 # 80010b90 <cpus>
    80001a8a:	953e                	add	a0,a0,a5
    80001a8c:	6422                	ld	s0,8(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret

0000000080001a92 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	1000                	addi	s0,sp,32
  push_off();
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	0ee080e7          	jalr	238(ra) # 80000b8a <push_off>
    80001aa4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa6:	2781                	sext.w	a5,a5
    80001aa8:	079e                	slli	a5,a5,0x7
    80001aaa:	0000f717          	auipc	a4,0xf
    80001aae:	0b670713          	addi	a4,a4,182 # 80010b60 <pid_lock>
    80001ab2:	97ba                	add	a5,a5,a4
    80001ab4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	174080e7          	jalr	372(ra) # 80000c2a <pop_off>
  return p;
}
    80001abe:	8526                	mv	a0,s1
    80001ac0:	60e2                	ld	ra,24(sp)
    80001ac2:	6442                	ld	s0,16(sp)
    80001ac4:	64a2                	ld	s1,8(sp)
    80001ac6:	6105                	addi	sp,sp,32
    80001ac8:	8082                	ret

0000000080001aca <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001aca:	1141                	addi	sp,sp,-16
    80001acc:	e406                	sd	ra,8(sp)
    80001ace:	e022                	sd	s0,0(sp)
    80001ad0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	fc0080e7          	jalr	-64(ra) # 80001a92 <myproc>
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1b0080e7          	jalr	432(ra) # 80000c8a <release>

  if (first)
    80001ae2:	00007797          	auipc	a5,0x7
    80001ae6:	d8e7a783          	lw	a5,-626(a5) # 80008870 <first.1>
    80001aea:	eb89                	bnez	a5,80001afc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aec:	00001097          	auipc	ra,0x1
    80001af0:	f68080e7          	jalr	-152(ra) # 80002a54 <usertrapret>
}
    80001af4:	60a2                	ld	ra,8(sp)
    80001af6:	6402                	ld	s0,0(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret
    first = 0;
    80001afc:	00007797          	auipc	a5,0x7
    80001b00:	d607aa23          	sw	zero,-652(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001b04:	4505                	li	a0,1
    80001b06:	00002097          	auipc	ra,0x2
    80001b0a:	ec8080e7          	jalr	-312(ra) # 800039ce <fsinit>
    80001b0e:	bff9                	j	80001aec <forkret+0x22>

0000000080001b10 <allocpid>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1c:	0000f917          	auipc	s2,0xf
    80001b20:	04490913          	addi	s2,s2,68 # 80010b60 <pid_lock>
    80001b24:	854a                	mv	a0,s2
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	0b0080e7          	jalr	176(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	d4678793          	addi	a5,a5,-698 # 80008874 <nextpid>
    80001b36:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b38:	0014871b          	addiw	a4,s1,1
    80001b3c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	14a080e7          	jalr	330(ra) # 80000c8a <release>
}
    80001b48:	8526                	mv	a0,s1
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <proc_pagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	7c4080e7          	jalr	1988(ra) # 80001328 <uvmcreate>
    80001b6c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b6e:	c121                	beqz	a0,80001bae <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b70:	4729                	li	a4,10
    80001b72:	00005697          	auipc	a3,0x5
    80001b76:	48e68693          	addi	a3,a3,1166 # 80007000 <_trampoline>
    80001b7a:	6605                	lui	a2,0x1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	51a080e7          	jalr	1306(ra) # 8000109e <mappages>
    80001b8c:	02054863          	bltz	a0,80001bbc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b90:	4719                	li	a4,6
    80001b92:	06093683          	ld	a3,96(s2)
    80001b96:	6605                	lui	a2,0x1
    80001b98:	020005b7          	lui	a1,0x2000
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05b6                	slli	a1,a1,0xd
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	4fc080e7          	jalr	1276(ra) # 8000109e <mappages>
    80001baa:	02054163          	bltz	a0,80001bcc <proc_pagetable+0x76>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret
    uvmfree(pagetable, 0);
    80001bbc:	4581                	li	a1,0
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	00000097          	auipc	ra,0x0
    80001bc4:	96c080e7          	jalr	-1684(ra) # 8000152c <uvmfree>
    return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	b7d5                	j	80001bae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bcc:	4681                	li	a3,0
    80001bce:	4605                	li	a2,1
    80001bd0:	040005b7          	lui	a1,0x4000
    80001bd4:	15fd                	addi	a1,a1,-1
    80001bd6:	05b2                	slli	a1,a1,0xc
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	68a080e7          	jalr	1674(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001be2:	4581                	li	a1,0
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	946080e7          	jalr	-1722(ra) # 8000152c <uvmfree>
    return 0;
    80001bee:	4481                	li	s1,0
    80001bf0:	bf7d                	j	80001bae <proc_pagetable+0x58>

0000000080001bf2 <proc_freepagetable>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	e04a                	sd	s2,0(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
    80001c00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c02:	4681                	li	a3,0
    80001c04:	4605                	li	a2,1
    80001c06:	040005b7          	lui	a1,0x4000
    80001c0a:	15fd                	addi	a1,a1,-1
    80001c0c:	05b2                	slli	a1,a1,0xc
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	656080e7          	jalr	1622(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c16:	4681                	li	a3,0
    80001c18:	4605                	li	a2,1
    80001c1a:	020005b7          	lui	a1,0x2000
    80001c1e:	15fd                	addi	a1,a1,-1
    80001c20:	05b6                	slli	a1,a1,0xd
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	640080e7          	jalr	1600(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c2c:	85ca                	mv	a1,s2
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	8fc080e7          	jalr	-1796(ra) # 8000152c <uvmfree>
}
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6902                	ld	s2,0(sp)
    80001c40:	6105                	addi	sp,sp,32
    80001c42:	8082                	ret

0000000080001c44 <freeproc>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	1000                	addi	s0,sp,32
    80001c4e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c50:	7128                	ld	a0,96(a0)
    80001c52:	c509                	beqz	a0,80001c5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	d96080e7          	jalr	-618(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001c5c:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001c60:	6ca8                	ld	a0,88(s1)
    80001c62:	c511                	beqz	a0,80001c6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c64:	68ac                	ld	a1,80(s1)
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	f8c080e7          	jalr	-116(ra) # 80001bf2 <proc_freepagetable>
  p->pagetable = 0;
    80001c6e:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c72:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001c76:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c7a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c7e:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c82:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c86:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c8a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c8e:	0004ac23          	sw	zero,24(s1)
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <allocproc>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	e04a                	sd	s2,0(sp)
    80001ca6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ca8:	0000f497          	auipc	s1,0xf
    80001cac:	2e848493          	addi	s1,s1,744 # 80010f90 <proc>
    80001cb0:	00017917          	auipc	s2,0x17
    80001cb4:	ee090913          	addi	s2,s2,-288 # 80018b90 <mlfq>
    acquire(&p->lock);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	f1c080e7          	jalr	-228(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001cc2:	4c9c                	lw	a5,24(s1)
    80001cc4:	cf81                	beqz	a5,80001cdc <allocproc+0x40>
      release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fc2080e7          	jalr	-62(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cd0:	1f048493          	addi	s1,s1,496
    80001cd4:	ff2492e3          	bne	s1,s2,80001cb8 <allocproc+0x1c>
  return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	a045                	j	80001d7a <allocproc+0xde>
  p->pid = allocpid();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	e34080e7          	jalr	-460(ra) # 80001b10 <allocpid>
    80001ce4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ce6:	4785                	li	a5,1
    80001ce8:	cc9c                	sw	a5,24(s1)
  p->cur_ticks=0;
    80001cea:	1c04a823          	sw	zero,464(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	df8080e7          	jalr	-520(ra) # 80000ae6 <kalloc>
    80001cf6:	892a                	mv	s2,a0
    80001cf8:	f0a8                	sd	a0,96(s1)
    80001cfa:	c559                	beqz	a0,80001d88 <allocproc+0xec>
  p->readcallcount=0;
    80001cfc:	0404a023          	sw	zero,64(s1)
  p->pagetable = proc_pagetable(p);
    80001d00:	8526                	mv	a0,s1
    80001d02:	00000097          	auipc	ra,0x0
    80001d06:	e54080e7          	jalr	-428(ra) # 80001b56 <proc_pagetable>
    80001d0a:	892a                	mv	s2,a0
    80001d0c:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001d0e:	c949                	beqz	a0,80001da0 <allocproc+0x104>
  memset(&p->context, 0, sizeof(p->context));
    80001d10:	07000613          	li	a2,112
    80001d14:	4581                	li	a1,0
    80001d16:	06848513          	addi	a0,s1,104
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	fb8080e7          	jalr	-72(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d22:	00000797          	auipc	a5,0x0
    80001d26:	da878793          	addi	a5,a5,-600 # 80001aca <forkret>
    80001d2a:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d2c:	64bc                	ld	a5,72(s1)
    80001d2e:	6705                	lui	a4,0x1
    80001d30:	97ba                	add	a5,a5,a4
    80001d32:	f8bc                	sd	a5,112(s1)
  p->rtime = 0;
    80001d34:	1604a823          	sw	zero,368(s1)
  p->etime = 0;
    80001d38:	1604ac23          	sw	zero,376(s1)
  p->ctime = ticks;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	bb47a783          	lw	a5,-1100(a5) # 800088f0 <ticks>
    80001d44:	16f4aa23          	sw	a5,372(s1)
  p->sigalarm = 0;
    80001d48:	1804a423          	sw	zero,392(s1)
  p->ticksn = 0;
    80001d4c:	1604ae23          	sw	zero,380(s1)
  p->ticksp = 0;
    80001d50:	1804a023          	sw	zero,384(s1)
  p->tickspa = 0;
    80001d54:	1804a223          	sw	zero,388(s1)
  p->handler = 0;
    80001d58:	1e04b423          	sd	zero,488(s1)
  p->is_sigalarm = 0;
    80001d5c:	1804ac23          	sw	zero,408(s1)
  p->clockval = 0;
    80001d60:	1804ae23          	sw	zero,412(s1)
  p->completed_clockval = 0;
    80001d64:	1a04a023          	sw	zero,416(s1)
  p->ticks_present=ticks;
    80001d68:	1cf4a423          	sw	a5,456(s1)
  p->present_in_queue=0;
    80001d6c:	1c04a023          	sw	zero,448(s1)
  p->queue_level=0;
    80001d70:	1a04ae23          	sw	zero,444(s1)
  p->change_queue=1<<p->queue_level;
    80001d74:	4785                	li	a5,1
    80001d76:	1cf4a223          	sw	a5,452(s1)
}
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6902                	ld	s2,0(sp)
    80001d84:	6105                	addi	sp,sp,32
    80001d86:	8082                	ret
    freeproc(p);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	eba080e7          	jalr	-326(ra) # 80001c44 <freeproc>
    release(&p->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	ef6080e7          	jalr	-266(ra) # 80000c8a <release>
    return 0;
    80001d9c:	84ca                	mv	s1,s2
    80001d9e:	bff1                	j	80001d7a <allocproc+0xde>
    freeproc(p);
    80001da0:	8526                	mv	a0,s1
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	ea2080e7          	jalr	-350(ra) # 80001c44 <freeproc>
    release(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	ede080e7          	jalr	-290(ra) # 80000c8a <release>
    return 0;
    80001db4:	84ca                	mv	s1,s2
    80001db6:	b7d1                	j	80001d7a <allocproc+0xde>

0000000080001db8 <userinit>:
{
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	eda080e7          	jalr	-294(ra) # 80001c9c <allocproc>
    80001dca:	84aa                	mv	s1,a0
  initproc = p;
    80001dcc:	00007797          	auipc	a5,0x7
    80001dd0:	b0a7be23          	sd	a0,-1252(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dd4:	03400613          	li	a2,52
    80001dd8:	00007597          	auipc	a1,0x7
    80001ddc:	aa858593          	addi	a1,a1,-1368 # 80008880 <initcode>
    80001de0:	6d28                	ld	a0,88(a0)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	574080e7          	jalr	1396(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001dea:	6785                	lui	a5,0x1
    80001dec:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dee:	70b8                	ld	a4,96(s1)
    80001df0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001df4:	70b8                	ld	a4,96(s1)
    80001df6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df8:	4641                	li	a2,16
    80001dfa:	00006597          	auipc	a1,0x6
    80001dfe:	40e58593          	addi	a1,a1,1038 # 80008208 <digits+0x1c8>
    80001e02:	16048513          	addi	a0,s1,352
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	016080e7          	jalr	22(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e0e:	00006517          	auipc	a0,0x6
    80001e12:	40a50513          	addi	a0,a0,1034 # 80008218 <digits+0x1d8>
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	5da080e7          	jalr	1498(ra) # 800043f0 <namei>
    80001e1e:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e22:	478d                	li	a5,3
    80001e24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e26:	8526                	mv	a0,s1
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	e62080e7          	jalr	-414(ra) # 80000c8a <release>
}
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret

0000000080001e3a <growproc>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	e04a                	sd	s2,0(sp)
    80001e44:	1000                	addi	s0,sp,32
    80001e46:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	c4a080e7          	jalr	-950(ra) # 80001a92 <myproc>
    80001e50:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e52:	692c                	ld	a1,80(a0)
  if (n > 0)
    80001e54:	01204c63          	bgtz	s2,80001e6c <growproc+0x32>
  else if (n < 0)
    80001e58:	02094663          	bltz	s2,80001e84 <growproc+0x4a>
  p->sz = sz;
    80001e5c:	e8ac                	sd	a1,80(s1)
  return 0;
    80001e5e:	4501                	li	a0,0
}
    80001e60:	60e2                	ld	ra,24(sp)
    80001e62:	6442                	ld	s0,16(sp)
    80001e64:	64a2                	ld	s1,8(sp)
    80001e66:	6902                	ld	s2,0(sp)
    80001e68:	6105                	addi	sp,sp,32
    80001e6a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e6c:	4691                	li	a3,4
    80001e6e:	00b90633          	add	a2,s2,a1
    80001e72:	6d28                	ld	a0,88(a0)
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	59c080e7          	jalr	1436(ra) # 80001410 <uvmalloc>
    80001e7c:	85aa                	mv	a1,a0
    80001e7e:	fd79                	bnez	a0,80001e5c <growproc+0x22>
      return -1;
    80001e80:	557d                	li	a0,-1
    80001e82:	bff9                	j	80001e60 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e84:	00b90633          	add	a2,s2,a1
    80001e88:	6d28                	ld	a0,88(a0)
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	53e080e7          	jalr	1342(ra) # 800013c8 <uvmdealloc>
    80001e92:	85aa                	mv	a1,a0
    80001e94:	b7e1                	j	80001e5c <growproc+0x22>

0000000080001e96 <fork>:
{
    80001e96:	7139                	addi	sp,sp,-64
    80001e98:	fc06                	sd	ra,56(sp)
    80001e9a:	f822                	sd	s0,48(sp)
    80001e9c:	f426                	sd	s1,40(sp)
    80001e9e:	f04a                	sd	s2,32(sp)
    80001ea0:	ec4e                	sd	s3,24(sp)
    80001ea2:	e852                	sd	s4,16(sp)
    80001ea4:	e456                	sd	s5,8(sp)
    80001ea6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	bea080e7          	jalr	-1046(ra) # 80001a92 <myproc>
    80001eb0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	dea080e7          	jalr	-534(ra) # 80001c9c <allocproc>
    80001eba:	10050c63          	beqz	a0,80001fd2 <fork+0x13c>
    80001ebe:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ec0:	050ab603          	ld	a2,80(s5)
    80001ec4:	6d2c                	ld	a1,88(a0)
    80001ec6:	058ab503          	ld	a0,88(s5)
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	69a080e7          	jalr	1690(ra) # 80001564 <uvmcopy>
    80001ed2:	04054863          	bltz	a0,80001f22 <fork+0x8c>
  np->sz = p->sz;
    80001ed6:	050ab783          	ld	a5,80(s5)
    80001eda:	04fa3823          	sd	a5,80(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ede:	060ab683          	ld	a3,96(s5)
    80001ee2:	87b6                	mv	a5,a3
    80001ee4:	060a3703          	ld	a4,96(s4)
    80001ee8:	12068693          	addi	a3,a3,288
    80001eec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef0:	6788                	ld	a0,8(a5)
    80001ef2:	6b8c                	ld	a1,16(a5)
    80001ef4:	6f90                	ld	a2,24(a5)
    80001ef6:	01073023          	sd	a6,0(a4)
    80001efa:	e708                	sd	a0,8(a4)
    80001efc:	eb0c                	sd	a1,16(a4)
    80001efe:	ef10                	sd	a2,24(a4)
    80001f00:	02078793          	addi	a5,a5,32
    80001f04:	02070713          	addi	a4,a4,32
    80001f08:	fed792e3          	bne	a5,a3,80001eec <fork+0x56>
  np->trapframe->a0 = 0;
    80001f0c:	060a3783          	ld	a5,96(s4)
    80001f10:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f14:	0d8a8493          	addi	s1,s5,216
    80001f18:	0d8a0913          	addi	s2,s4,216
    80001f1c:	158a8993          	addi	s3,s5,344
    80001f20:	a00d                	j	80001f42 <fork+0xac>
    freeproc(np);
    80001f22:	8552                	mv	a0,s4
    80001f24:	00000097          	auipc	ra,0x0
    80001f28:	d20080e7          	jalr	-736(ra) # 80001c44 <freeproc>
    release(&np->lock);
    80001f2c:	8552                	mv	a0,s4
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d5c080e7          	jalr	-676(ra) # 80000c8a <release>
    return -1;
    80001f36:	597d                	li	s2,-1
    80001f38:	a059                	j	80001fbe <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001f3a:	04a1                	addi	s1,s1,8
    80001f3c:	0921                	addi	s2,s2,8
    80001f3e:	01348b63          	beq	s1,s3,80001f54 <fork+0xbe>
    if (p->ofile[i])
    80001f42:	6088                	ld	a0,0(s1)
    80001f44:	d97d                	beqz	a0,80001f3a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f46:	00003097          	auipc	ra,0x3
    80001f4a:	b40080e7          	jalr	-1216(ra) # 80004a86 <filedup>
    80001f4e:	00a93023          	sd	a0,0(s2)
    80001f52:	b7e5                	j	80001f3a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f54:	158ab503          	ld	a0,344(s5)
    80001f58:	00002097          	auipc	ra,0x2
    80001f5c:	cb4080e7          	jalr	-844(ra) # 80003c0c <idup>
    80001f60:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	160a8593          	addi	a1,s5,352
    80001f6a:	160a0513          	addi	a0,s4,352
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	eae080e7          	jalr	-338(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f76:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f7a:	8552                	mv	a0,s4
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	d0e080e7          	jalr	-754(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001f84:	0000f497          	auipc	s1,0xf
    80001f88:	bf448493          	addi	s1,s1,-1036 # 80010b78 <wait_lock>
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	c48080e7          	jalr	-952(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f96:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001fa4:	8552                	mv	a0,s4
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c30080e7          	jalr	-976(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fb4:	8552                	mv	a0,s4
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	cd4080e7          	jalr	-812(ra) # 80000c8a <release>
}
    80001fbe:	854a                	mv	a0,s2
    80001fc0:	70e2                	ld	ra,56(sp)
    80001fc2:	7442                	ld	s0,48(sp)
    80001fc4:	74a2                	ld	s1,40(sp)
    80001fc6:	7902                	ld	s2,32(sp)
    80001fc8:	69e2                	ld	s3,24(sp)
    80001fca:	6a42                	ld	s4,16(sp)
    80001fcc:	6aa2                	ld	s5,8(sp)
    80001fce:	6121                	addi	sp,sp,64
    80001fd0:	8082                	ret
    return -1;
    80001fd2:	597d                	li	s2,-1
    80001fd4:	b7ed                	j	80001fbe <fork+0x128>

0000000080001fd6 <scheduler>:
{
    80001fd6:	711d                	addi	sp,sp,-96
    80001fd8:	ec86                	sd	ra,88(sp)
    80001fda:	e8a2                	sd	s0,80(sp)
    80001fdc:	e4a6                	sd	s1,72(sp)
    80001fde:	e0ca                	sd	s2,64(sp)
    80001fe0:	fc4e                	sd	s3,56(sp)
    80001fe2:	f852                	sd	s4,48(sp)
    80001fe4:	f456                	sd	s5,40(sp)
    80001fe6:	f05a                	sd	s6,32(sp)
    80001fe8:	ec5e                	sd	s7,24(sp)
    80001fea:	e862                	sd	s8,16(sp)
    80001fec:	e466                	sd	s9,8(sp)
    80001fee:	1080                	addi	s0,sp,96
    80001ff0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ff2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ff4:	00779c13          	slli	s8,a5,0x7
    80001ff8:	0000f717          	auipc	a4,0xf
    80001ffc:	b6870713          	addi	a4,a4,-1176 # 80010b60 <pid_lock>
    80002000:	9762                	add	a4,a4,s8
    80002002:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p->context);
    80002006:	0000f717          	auipc	a4,0xf
    8000200a:	b9270713          	addi	a4,a4,-1134 # 80010b98 <cpus+0x8>
    8000200e:	9c3a                	add	s8,s8,a4
      if (p->state == RUNNABLE && ticks - p->ticks_present >= tickforage)
    80002010:	00007a17          	auipc	s4,0x7
    80002014:	8e0a0a13          	addi	s4,s4,-1824 # 800088f0 <ticks>
          remove (&mlfq[p->queue_level], p->pid);
    80002018:	00017a97          	auipc	s5,0x17
    8000201c:	b78a8a93          	addi	s5,s5,-1160 # 80018b90 <mlfq>
      c->proc = p;
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	0000fb97          	auipc	s7,0xf
    80002026:	b3eb8b93          	addi	s7,s7,-1218 # 80010b60 <pid_lock>
    8000202a:	9bbe                	add	s7,s7,a5
    8000202c:	aa21                	j	80002144 <scheduler+0x16e>
          p->present_in_queue = 0;
    8000202e:	1c04a023          	sw	zero,448(s1)
          remove (&mlfq[p->queue_level], p->pid);
    80002032:	1bc4e783          	lwu	a5,444(s1)
    80002036:	00679513          	slli	a0,a5,0x6
    8000203a:	953e                	add	a0,a0,a5
    8000203c:	050e                	slli	a0,a0,0x3
    8000203e:	588c                	lw	a1,48(s1)
    80002040:	9556                	add	a0,a0,s5
    80002042:	00000097          	auipc	ra,0x0
    80002046:	88c080e7          	jalr	-1908(ra) # 800018ce <remove>
        if (p->state==RUNNABLE && p->queue_level!=0){
    8000204a:	4c9c                	lw	a5,24(s1)
    8000204c:	03278763          	beq	a5,s2,8000207a <scheduler+0xa4>
        p->ticks_present = ticks;
    80002050:	000a2783          	lw	a5,0(s4)
    80002054:	1cf4a423          	sw	a5,456(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80002058:	1f048493          	addi	s1,s1,496
    8000205c:	03348663          	beq	s1,s3,80002088 <scheduler+0xb2>
      if (p->state == RUNNABLE && ticks - p->ticks_present >= tickforage)
    80002060:	4c9c                	lw	a5,24(s1)
    80002062:	ff279be3          	bne	a5,s2,80002058 <scheduler+0x82>
    80002066:	000a2783          	lw	a5,0(s4)
    8000206a:	1c84a703          	lw	a4,456(s1)
    8000206e:	9f99                	subw	a5,a5,a4
    80002070:	fefcf4e3          	bgeu	s9,a5,80002058 <scheduler+0x82>
        if ( p->state==RUNNABLE && p->present_in_queue!=0 )
    80002074:	1c04a783          	lw	a5,448(s1)
    80002078:	fbdd                	bnez	a5,8000202e <scheduler+0x58>
        if (p->state==RUNNABLE && p->queue_level!=0){
    8000207a:	1bc4a783          	lw	a5,444(s1)
    8000207e:	dbe9                	beqz	a5,80002050 <scheduler+0x7a>
          p->queue_level=p->queue_level-1;
    80002080:	37fd                	addiw	a5,a5,-1
    80002082:	1af4ae23          	sw	a5,444(s1)
    80002086:	b7e9                	j	80002050 <scheduler+0x7a>
    for (p = proc; p < &proc[NPROC]; p++)
    80002088:	0000f497          	auipc	s1,0xf
    8000208c:	f0848493          	addi	s1,s1,-248 # 80010f90 <proc>
        p->present_in_queue = 1;
    80002090:	4c85                	li	s9,1
    80002092:	a029                	j	8000209c <scheduler+0xc6>
    for (p = proc; p < &proc[NPROC]; p++)
    80002094:	1f048493          	addi	s1,s1,496
    80002098:	03348763          	beq	s1,s3,800020c6 <scheduler+0xf0>
      if (p->state == RUNNABLE && p->present_in_queue==0)
    8000209c:	4c9c                	lw	a5,24(s1)
    8000209e:	ff279be3          	bne	a5,s2,80002094 <scheduler+0xbe>
    800020a2:	1c04a783          	lw	a5,448(s1)
    800020a6:	f7fd                	bnez	a5,80002094 <scheduler+0xbe>
        p->present_in_queue = 1;
    800020a8:	1d94a023          	sw	s9,448(s1)
        pushback(&mlfq[p->queue_level], p);
    800020ac:	1bc4e783          	lwu	a5,444(s1)
    800020b0:	00679513          	slli	a0,a5,0x6
    800020b4:	953e                	add	a0,a0,a5
    800020b6:	050e                	slli	a0,a0,0x3
    800020b8:	85a6                	mv	a1,s1
    800020ba:	9556                	add	a0,a0,s5
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	7b2080e7          	jalr	1970(ra) # 8000186e <pushback>
    800020c4:	bfc1                	j	80002094 <scheduler+0xbe>
    800020c6:	00017c97          	auipc	s9,0x17
    800020ca:	acac8c93          	addi	s9,s9,-1334 # 80018b90 <mlfq>
      while (size(&mlfq[i])!=0)
    800020ce:	200ca783          	lw	a5,512(s9)
    800020d2:	c3d9                	beqz	a5,80002158 <scheduler+0x182>
    return a->n[0];
    800020d4:	000cb483          	ld	s1,0(s9)
        p->present_in_queue = 0;
    800020d8:	1c04a023          	sw	zero,448(s1)
        popfront(&mlfq[p->queue_level]);
    800020dc:	1bc4e783          	lwu	a5,444(s1)
    800020e0:	00679513          	slli	a0,a5,0x6
    800020e4:	953e                	add	a0,a0,a5
    800020e6:	050e                	slli	a0,a0,0x3
    800020e8:	9556                	add	a0,a0,s5
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	74c080e7          	jalr	1868(ra) # 80001836 <popfront>
        if (p->state == RUNNABLE)
    800020f2:	4c9c                	lw	a5,24(s1)
    800020f4:	fd279de3          	bne	a5,s2,800020ce <scheduler+0xf8>
          p->ticks_present = ticks;
    800020f8:	000a2783          	lw	a5,0(s4)
    800020fc:	1cf4a423          	sw	a5,456(s1)
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      p->state = RUNNING;
    8000210a:	4791                	li	a5,4
    8000210c:	cc9c                	sw	a5,24(s1)
      p->ticks_present = ticks;
    8000210e:	000a2783          	lw	a5,0(s4)
    80002112:	1cf4a423          	sw	a5,456(s1)
      p->change_queue = 1 << p->queue_level;
    80002116:	1bc4a703          	lw	a4,444(s1)
    8000211a:	4785                	li	a5,1
    8000211c:	00e797bb          	sllw	a5,a5,a4
    80002120:	1cf4a223          	sw	a5,452(s1)
      c->proc = p;
    80002124:	029bb823          	sd	s1,48(s7)
      swtch(&c->context, &p->context);
    80002128:	06848593          	addi	a1,s1,104
    8000212c:	8562                	mv	a0,s8
    8000212e:	00001097          	auipc	ra,0x1
    80002132:	87c080e7          	jalr	-1924(ra) # 800029aa <swtch>
      c->proc = 0;
    80002136:	020bb823          	sd	zero,48(s7)
      release(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b4e080e7          	jalr	-1202(ra) # 80000c8a <release>
      if (p->state == RUNNABLE && ticks - p->ticks_present >= tickforage)
    80002144:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002146:	00017997          	auipc	s3,0x17
    8000214a:	a4a98993          	addi	s3,s3,-1462 # 80018b90 <mlfq>
    8000214e:	00017b17          	auipc	s6,0x17
    80002152:	262b0b13          	addi	s6,s6,610 # 800193b0 <tickslock>
    80002156:	a801                	j	80002166 <scheduler+0x190>
    for (int i = 0; i < 4; i++)
    80002158:	208c8c93          	addi	s9,s9,520
    8000215c:	f76c99e3          	bne	s9,s6,800020ce <scheduler+0xf8>
    if (p->state == RUNNABLE)
    80002160:	4c9c                	lw	a5,24(s1)
    80002162:	f9278fe3          	beq	a5,s2,80002100 <scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002166:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000216a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000216e:	10079073          	csrw	sstatus,a5
  for (p = proc; p < &proc[NPROC]; p++)
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	e1e48493          	addi	s1,s1,-482 # 80010f90 <proc>
      if (p->state == RUNNABLE && ticks - p->ticks_present >= tickforage)
    8000217a:	02200c93          	li	s9,34
    8000217e:	b5cd                	j	80002060 <scheduler+0x8a>

0000000080002180 <sched>:
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	904080e7          	jalr	-1788(ra) # 80001a92 <myproc>
    80002196:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	9c4080e7          	jalr	-1596(ra) # 80000b5c <holding>
    800021a0:	c93d                	beqz	a0,80002216 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a2:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021a4:	2781                	sext.w	a5,a5
    800021a6:	079e                	slli	a5,a5,0x7
    800021a8:	0000f717          	auipc	a4,0xf
    800021ac:	9b870713          	addi	a4,a4,-1608 # 80010b60 <pid_lock>
    800021b0:	97ba                	add	a5,a5,a4
    800021b2:	0a87a703          	lw	a4,168(a5)
    800021b6:	4785                	li	a5,1
    800021b8:	06f71763          	bne	a4,a5,80002226 <sched+0xa6>
  if (p->state == RUNNING)
    800021bc:	4c98                	lw	a4,24(s1)
    800021be:	4791                	li	a5,4
    800021c0:	06f70b63          	beq	a4,a5,80002236 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021c8:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021ca:	efb5                	bnez	a5,80002246 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021cc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ce:	0000f917          	auipc	s2,0xf
    800021d2:	99290913          	addi	s2,s2,-1646 # 80010b60 <pid_lock>
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	97ca                	add	a5,a5,s2
    800021dc:	0ac7a983          	lw	s3,172(a5)
    800021e0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021e2:	2781                	sext.w	a5,a5
    800021e4:	079e                	slli	a5,a5,0x7
    800021e6:	0000f597          	auipc	a1,0xf
    800021ea:	9b258593          	addi	a1,a1,-1614 # 80010b98 <cpus+0x8>
    800021ee:	95be                	add	a1,a1,a5
    800021f0:	06848513          	addi	a0,s1,104
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	7b6080e7          	jalr	1974(ra) # 800029aa <swtch>
    800021fc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021fe:	2781                	sext.w	a5,a5
    80002200:	079e                	slli	a5,a5,0x7
    80002202:	97ca                	add	a5,a5,s2
    80002204:	0b37a623          	sw	s3,172(a5)
}
    80002208:	70a2                	ld	ra,40(sp)
    8000220a:	7402                	ld	s0,32(sp)
    8000220c:	64e2                	ld	s1,24(sp)
    8000220e:	6942                	ld	s2,16(sp)
    80002210:	69a2                	ld	s3,8(sp)
    80002212:	6145                	addi	sp,sp,48
    80002214:	8082                	ret
    panic("sched p->lock");
    80002216:	00006517          	auipc	a0,0x6
    8000221a:	00a50513          	addi	a0,a0,10 # 80008220 <digits+0x1e0>
    8000221e:	ffffe097          	auipc	ra,0xffffe
    80002222:	320080e7          	jalr	800(ra) # 8000053e <panic>
    panic("sched locks");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	00a50513          	addi	a0,a0,10 # 80008230 <digits+0x1f0>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    panic("sched running");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	00a50513          	addi	a0,a0,10 # 80008240 <digits+0x200>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	300080e7          	jalr	768(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	00a50513          	addi	a0,a0,10 # 80008250 <digits+0x210>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2f0080e7          	jalr	752(ra) # 8000053e <panic>

0000000080002256 <yield>:
{
    80002256:	1101                	addi	sp,sp,-32
    80002258:	ec06                	sd	ra,24(sp)
    8000225a:	e822                	sd	s0,16(sp)
    8000225c:	e426                	sd	s1,8(sp)
    8000225e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	832080e7          	jalr	-1998(ra) # 80001a92 <myproc>
    80002268:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002272:	478d                	li	a5,3
    80002274:	cc9c                	sw	a5,24(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	f0a080e7          	jalr	-246(ra) # 80002180 <sched>
  release(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a0a080e7          	jalr	-1526(ra) # 80000c8a <release>
}
    80002288:	60e2                	ld	ra,24(sp)
    8000228a:	6442                	ld	s0,16(sp)
    8000228c:	64a2                	ld	s1,8(sp)
    8000228e:	6105                	addi	sp,sp,32
    80002290:	8082                	ret

0000000080002292 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002292:	7179                	addi	sp,sp,-48
    80002294:	f406                	sd	ra,40(sp)
    80002296:	f022                	sd	s0,32(sp)
    80002298:	ec26                	sd	s1,24(sp)
    8000229a:	e84a                	sd	s2,16(sp)
    8000229c:	e44e                	sd	s3,8(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	89aa                	mv	s3,a0
    800022a2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	7ee080e7          	jalr	2030(ra) # 80001a92 <myproc>
    800022ac:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	928080e7          	jalr	-1752(ra) # 80000bd6 <acquire>
  release(lk);
    800022b6:	854a                	mv	a0,s2
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9d2080e7          	jalr	-1582(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800022c0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022c4:	4789                	li	a5,2
    800022c6:	cc9c                	sw	a5,24(s1)

  sched();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	eb8080e7          	jalr	-328(ra) # 80002180 <sched>

  // Tidy up.
  p->chan = 0;
    800022d0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9b4080e7          	jalr	-1612(ra) # 80000c8a <release>
  acquire(lk);
    800022de:	854a                	mv	a0,s2
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	8f6080e7          	jalr	-1802(ra) # 80000bd6 <acquire>
}
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6145                	addi	sp,sp,48
    800022f4:	8082                	ret

00000000800022f6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022f6:	7139                	addi	sp,sp,-64
    800022f8:	fc06                	sd	ra,56(sp)
    800022fa:	f822                	sd	s0,48(sp)
    800022fc:	f426                	sd	s1,40(sp)
    800022fe:	f04a                	sd	s2,32(sp)
    80002300:	ec4e                	sd	s3,24(sp)
    80002302:	e852                	sd	s4,16(sp)
    80002304:	e456                	sd	s5,8(sp)
    80002306:	0080                	addi	s0,sp,64
    80002308:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000230a:	0000f497          	auipc	s1,0xf
    8000230e:	c8648493          	addi	s1,s1,-890 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002312:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002314:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002316:	00017917          	auipc	s2,0x17
    8000231a:	87a90913          	addi	s2,s2,-1926 # 80018b90 <mlfq>
    8000231e:	a811                	j	80002332 <wakeup+0x3c>
      }
      release(&p->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000232a:	1f048493          	addi	s1,s1,496
    8000232e:	03248663          	beq	s1,s2,8000235a <wakeup+0x64>
    if (p != myproc())
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	760080e7          	jalr	1888(ra) # 80001a92 <myproc>
    8000233a:	fea488e3          	beq	s1,a0,8000232a <wakeup+0x34>
      acquire(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	896080e7          	jalr	-1898(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002348:	4c9c                	lw	a5,24(s1)
    8000234a:	fd379be3          	bne	a5,s3,80002320 <wakeup+0x2a>
    8000234e:	709c                	ld	a5,32(s1)
    80002350:	fd4798e3          	bne	a5,s4,80002320 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002354:	0154ac23          	sw	s5,24(s1)
    80002358:	b7e1                	j	80002320 <wakeup+0x2a>
    }
  }
}
    8000235a:	70e2                	ld	ra,56(sp)
    8000235c:	7442                	ld	s0,48(sp)
    8000235e:	74a2                	ld	s1,40(sp)
    80002360:	7902                	ld	s2,32(sp)
    80002362:	69e2                	ld	s3,24(sp)
    80002364:	6a42                	ld	s4,16(sp)
    80002366:	6aa2                	ld	s5,8(sp)
    80002368:	6121                	addi	sp,sp,64
    8000236a:	8082                	ret

000000008000236c <reparent>:
{
    8000236c:	7179                	addi	sp,sp,-48
    8000236e:	f406                	sd	ra,40(sp)
    80002370:	f022                	sd	s0,32(sp)
    80002372:	ec26                	sd	s1,24(sp)
    80002374:	e84a                	sd	s2,16(sp)
    80002376:	e44e                	sd	s3,8(sp)
    80002378:	e052                	sd	s4,0(sp)
    8000237a:	1800                	addi	s0,sp,48
    8000237c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000237e:	0000f497          	auipc	s1,0xf
    80002382:	c1248493          	addi	s1,s1,-1006 # 80010f90 <proc>
      pp->parent = initproc;
    80002386:	00006a17          	auipc	s4,0x6
    8000238a:	562a0a13          	addi	s4,s4,1378 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000238e:	00017997          	auipc	s3,0x17
    80002392:	80298993          	addi	s3,s3,-2046 # 80018b90 <mlfq>
    80002396:	a029                	j	800023a0 <reparent+0x34>
    80002398:	1f048493          	addi	s1,s1,496
    8000239c:	01348d63          	beq	s1,s3,800023b6 <reparent+0x4a>
    if (pp->parent == p)
    800023a0:	7c9c                	ld	a5,56(s1)
    800023a2:	ff279be3          	bne	a5,s2,80002398 <reparent+0x2c>
      pp->parent = initproc;
    800023a6:	000a3503          	ld	a0,0(s4)
    800023aa:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023ac:	00000097          	auipc	ra,0x0
    800023b0:	f4a080e7          	jalr	-182(ra) # 800022f6 <wakeup>
    800023b4:	b7d5                	j	80002398 <reparent+0x2c>
}
    800023b6:	70a2                	ld	ra,40(sp)
    800023b8:	7402                	ld	s0,32(sp)
    800023ba:	64e2                	ld	s1,24(sp)
    800023bc:	6942                	ld	s2,16(sp)
    800023be:	69a2                	ld	s3,8(sp)
    800023c0:	6a02                	ld	s4,0(sp)
    800023c2:	6145                	addi	sp,sp,48
    800023c4:	8082                	ret

00000000800023c6 <exit>:
{
    800023c6:	7179                	addi	sp,sp,-48
    800023c8:	f406                	sd	ra,40(sp)
    800023ca:	f022                	sd	s0,32(sp)
    800023cc:	ec26                	sd	s1,24(sp)
    800023ce:	e84a                	sd	s2,16(sp)
    800023d0:	e44e                	sd	s3,8(sp)
    800023d2:	e052                	sd	s4,0(sp)
    800023d4:	1800                	addi	s0,sp,48
    800023d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	6ba080e7          	jalr	1722(ra) # 80001a92 <myproc>
    800023e0:	89aa                	mv	s3,a0
  if (p == initproc)
    800023e2:	00006797          	auipc	a5,0x6
    800023e6:	5067b783          	ld	a5,1286(a5) # 800088e8 <initproc>
    800023ea:	0d850493          	addi	s1,a0,216
    800023ee:	15850913          	addi	s2,a0,344
    800023f2:	02a79363          	bne	a5,a0,80002418 <exit+0x52>
    panic("init exiting");
    800023f6:	00006517          	auipc	a0,0x6
    800023fa:	e7250513          	addi	a0,a0,-398 # 80008268 <digits+0x228>
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	140080e7          	jalr	320(ra) # 8000053e <panic>
      fileclose(f);
    80002406:	00002097          	auipc	ra,0x2
    8000240a:	6d2080e7          	jalr	1746(ra) # 80004ad8 <fileclose>
      p->ofile[fd] = 0;
    8000240e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002412:	04a1                	addi	s1,s1,8
    80002414:	01248563          	beq	s1,s2,8000241e <exit+0x58>
    if (p->ofile[fd])
    80002418:	6088                	ld	a0,0(s1)
    8000241a:	f575                	bnez	a0,80002406 <exit+0x40>
    8000241c:	bfdd                	j	80002412 <exit+0x4c>
  begin_op();
    8000241e:	00002097          	auipc	ra,0x2
    80002422:	1ee080e7          	jalr	494(ra) # 8000460c <begin_op>
  iput(p->cwd);
    80002426:	1589b503          	ld	a0,344(s3)
    8000242a:	00002097          	auipc	ra,0x2
    8000242e:	9da080e7          	jalr	-1574(ra) # 80003e04 <iput>
  end_op();
    80002432:	00002097          	auipc	ra,0x2
    80002436:	25a080e7          	jalr	602(ra) # 8000468c <end_op>
  p->cwd = 0;
    8000243a:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000243e:	0000e497          	auipc	s1,0xe
    80002442:	73a48493          	addi	s1,s1,1850 # 80010b78 <wait_lock>
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
  reparent(p);
    80002450:	854e                	mv	a0,s3
    80002452:	00000097          	auipc	ra,0x0
    80002456:	f1a080e7          	jalr	-230(ra) # 8000236c <reparent>
  wakeup(p->parent);
    8000245a:	0389b503          	ld	a0,56(s3)
    8000245e:	00000097          	auipc	ra,0x0
    80002462:	e98080e7          	jalr	-360(ra) # 800022f6 <wakeup>
  acquire(&p->lock);
    80002466:	854e                	mv	a0,s3
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	76e080e7          	jalr	1902(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002470:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002474:	4795                	li	a5,5
    80002476:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000247a:	00006797          	auipc	a5,0x6
    8000247e:	4767a783          	lw	a5,1142(a5) # 800088f0 <ticks>
    80002482:	16f9ac23          	sw	a5,376(s3)
  release(&wait_lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
  sched();
    80002490:	00000097          	auipc	ra,0x0
    80002494:	cf0080e7          	jalr	-784(ra) # 80002180 <sched>
  panic("zombie exit");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	de050513          	addi	a0,a0,-544 # 80008278 <digits+0x238>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	09e080e7          	jalr	158(ra) # 8000053e <panic>

00000000800024a8 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024b8:	0000f497          	auipc	s1,0xf
    800024bc:	ad848493          	addi	s1,s1,-1320 # 80010f90 <proc>
    800024c0:	00016997          	auipc	s3,0x16
    800024c4:	6d098993          	addi	s3,s3,1744 # 80018b90 <mlfq>
  {
    acquire(&p->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	70c080e7          	jalr	1804(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800024d2:	589c                	lw	a5,48(s1)
    800024d4:	01278d63          	beq	a5,s2,800024ee <kill+0x46>

      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7b0080e7          	jalr	1968(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024e2:	1f048493          	addi	s1,s1,496
    800024e6:	ff3491e3          	bne	s1,s3,800024c8 <kill+0x20>
  }
  return -1;
    800024ea:	557d                	li	a0,-1
    800024ec:	a829                	j	80002506 <kill+0x5e>
      p->killed = 1;
    800024ee:	4785                	li	a5,1
    800024f0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800024f2:	4c98                	lw	a4,24(s1)
    800024f4:	4789                	li	a5,2
    800024f6:	00f70f63          	beq	a4,a5,80002514 <kill+0x6c>
      release(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
      return 0;
    80002504:	4501                	li	a0,0
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
        p->state = RUNNABLE;
    80002514:	478d                	li	a5,3
    80002516:	cc9c                	sw	a5,24(s1)
    80002518:	b7cd                	j	800024fa <kill+0x52>

000000008000251a <setkilled>:

void setkilled(struct proc *p)
{
    8000251a:	1101                	addi	sp,sp,-32
    8000251c:	ec06                	sd	ra,24(sp)
    8000251e:	e822                	sd	s0,16(sp)
    80002520:	e426                	sd	s1,8(sp)
    80002522:	1000                	addi	s0,sp,32
    80002524:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	6b0080e7          	jalr	1712(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000252e:	4785                	li	a5,1
    80002530:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002532:	8526                	mv	a0,s1
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	756080e7          	jalr	1878(ra) # 80000c8a <release>
}
    8000253c:	60e2                	ld	ra,24(sp)
    8000253e:	6442                	ld	s0,16(sp)
    80002540:	64a2                	ld	s1,8(sp)
    80002542:	6105                	addi	sp,sp,32
    80002544:	8082                	ret

0000000080002546 <killed>:

int killed(struct proc *p)
{
    80002546:	1101                	addi	sp,sp,-32
    80002548:	ec06                	sd	ra,24(sp)
    8000254a:	e822                	sd	s0,16(sp)
    8000254c:	e426                	sd	s1,8(sp)
    8000254e:	e04a                	sd	s2,0(sp)
    80002550:	1000                	addi	s0,sp,32
    80002552:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	682080e7          	jalr	1666(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000255c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	728080e7          	jalr	1832(ra) # 80000c8a <release>
  return k;
}
    8000256a:	854a                	mv	a0,s2
    8000256c:	60e2                	ld	ra,24(sp)
    8000256e:	6442                	ld	s0,16(sp)
    80002570:	64a2                	ld	s1,8(sp)
    80002572:	6902                	ld	s2,0(sp)
    80002574:	6105                	addi	sp,sp,32
    80002576:	8082                	ret

0000000080002578 <wait>:
{
    80002578:	715d                	addi	sp,sp,-80
    8000257a:	e486                	sd	ra,72(sp)
    8000257c:	e0a2                	sd	s0,64(sp)
    8000257e:	fc26                	sd	s1,56(sp)
    80002580:	f84a                	sd	s2,48(sp)
    80002582:	f44e                	sd	s3,40(sp)
    80002584:	f052                	sd	s4,32(sp)
    80002586:	ec56                	sd	s5,24(sp)
    80002588:	e85a                	sd	s6,16(sp)
    8000258a:	e45e                	sd	s7,8(sp)
    8000258c:	e062                	sd	s8,0(sp)
    8000258e:	0880                	addi	s0,sp,80
    80002590:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	500080e7          	jalr	1280(ra) # 80001a92 <myproc>
    8000259a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000259c:	0000e517          	auipc	a0,0xe
    800025a0:	5dc50513          	addi	a0,a0,1500 # 80010b78 <wait_lock>
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	632080e7          	jalr	1586(ra) # 80000bd6 <acquire>
    havekids = 0;
    800025ac:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800025ae:	4a15                	li	s4,5
        havekids = 1;
    800025b0:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025b2:	00016997          	auipc	s3,0x16
    800025b6:	5de98993          	addi	s3,s3,1502 # 80018b90 <mlfq>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025ba:	0000ec17          	auipc	s8,0xe
    800025be:	5bec0c13          	addi	s8,s8,1470 # 80010b78 <wait_lock>
    havekids = 0;
    800025c2:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025c4:	0000f497          	auipc	s1,0xf
    800025c8:	9cc48493          	addi	s1,s1,-1588 # 80010f90 <proc>
    800025cc:	a0bd                	j	8000263a <wait+0xc2>
          pid = pp->pid;
    800025ce:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025d2:	000b0e63          	beqz	s6,800025ee <wait+0x76>
    800025d6:	4691                	li	a3,4
    800025d8:	02c48613          	addi	a2,s1,44
    800025dc:	85da                	mv	a1,s6
    800025de:	05893503          	ld	a0,88(s2)
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	086080e7          	jalr	134(ra) # 80001668 <copyout>
    800025ea:	02054563          	bltz	a0,80002614 <wait+0x9c>
          freeproc(pp);
    800025ee:	8526                	mv	a0,s1
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	654080e7          	jalr	1620(ra) # 80001c44 <freeproc>
          release(&pp->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	690080e7          	jalr	1680(ra) # 80000c8a <release>
          release(&wait_lock);
    80002602:	0000e517          	auipc	a0,0xe
    80002606:	57650513          	addi	a0,a0,1398 # 80010b78 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	680080e7          	jalr	1664(ra) # 80000c8a <release>
          return pid;
    80002612:	a0b5                	j	8000267e <wait+0x106>
            release(&pp->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	674080e7          	jalr	1652(ra) # 80000c8a <release>
            release(&wait_lock);
    8000261e:	0000e517          	auipc	a0,0xe
    80002622:	55a50513          	addi	a0,a0,1370 # 80010b78 <wait_lock>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	664080e7          	jalr	1636(ra) # 80000c8a <release>
            return -1;
    8000262e:	59fd                	li	s3,-1
    80002630:	a0b9                	j	8000267e <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002632:	1f048493          	addi	s1,s1,496
    80002636:	03348463          	beq	s1,s3,8000265e <wait+0xe6>
      if (pp->parent == p)
    8000263a:	7c9c                	ld	a5,56(s1)
    8000263c:	ff279be3          	bne	a5,s2,80002632 <wait+0xba>
        acquire(&pp->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	594080e7          	jalr	1428(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000264a:	4c9c                	lw	a5,24(s1)
    8000264c:	f94781e3          	beq	a5,s4,800025ce <wait+0x56>
        release(&pp->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	638080e7          	jalr	1592(ra) # 80000c8a <release>
        havekids = 1;
    8000265a:	8756                	mv	a4,s5
    8000265c:	bfd9                	j	80002632 <wait+0xba>
    if (!havekids || killed(p))
    8000265e:	c719                	beqz	a4,8000266c <wait+0xf4>
    80002660:	854a                	mv	a0,s2
    80002662:	00000097          	auipc	ra,0x0
    80002666:	ee4080e7          	jalr	-284(ra) # 80002546 <killed>
    8000266a:	c51d                	beqz	a0,80002698 <wait+0x120>
      release(&wait_lock);
    8000266c:	0000e517          	auipc	a0,0xe
    80002670:	50c50513          	addi	a0,a0,1292 # 80010b78 <wait_lock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	616080e7          	jalr	1558(ra) # 80000c8a <release>
      return -1;
    8000267c:	59fd                	li	s3,-1
}
    8000267e:	854e                	mv	a0,s3
    80002680:	60a6                	ld	ra,72(sp)
    80002682:	6406                	ld	s0,64(sp)
    80002684:	74e2                	ld	s1,56(sp)
    80002686:	7942                	ld	s2,48(sp)
    80002688:	79a2                	ld	s3,40(sp)
    8000268a:	7a02                	ld	s4,32(sp)
    8000268c:	6ae2                	ld	s5,24(sp)
    8000268e:	6b42                	ld	s6,16(sp)
    80002690:	6ba2                	ld	s7,8(sp)
    80002692:	6c02                	ld	s8,0(sp)
    80002694:	6161                	addi	sp,sp,80
    80002696:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002698:	85e2                	mv	a1,s8
    8000269a:	854a                	mv	a0,s2
    8000269c:	00000097          	auipc	ra,0x0
    800026a0:	bf6080e7          	jalr	-1034(ra) # 80002292 <sleep>
    havekids = 0;
    800026a4:	bf39                	j	800025c2 <wait+0x4a>

00000000800026a6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a6:	7179                	addi	sp,sp,-48
    800026a8:	f406                	sd	ra,40(sp)
    800026aa:	f022                	sd	s0,32(sp)
    800026ac:	ec26                	sd	s1,24(sp)
    800026ae:	e84a                	sd	s2,16(sp)
    800026b0:	e44e                	sd	s3,8(sp)
    800026b2:	e052                	sd	s4,0(sp)
    800026b4:	1800                	addi	s0,sp,48
    800026b6:	84aa                	mv	s1,a0
    800026b8:	892e                	mv	s2,a1
    800026ba:	89b2                	mv	s3,a2
    800026bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026be:	fffff097          	auipc	ra,0xfffff
    800026c2:	3d4080e7          	jalr	980(ra) # 80001a92 <myproc>
  if (user_dst)
    800026c6:	c08d                	beqz	s1,800026e8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800026c8:	86d2                	mv	a3,s4
    800026ca:	864e                	mv	a2,s3
    800026cc:	85ca                	mv	a1,s2
    800026ce:	6d28                	ld	a0,88(a0)
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	f98080e7          	jalr	-104(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d8:	70a2                	ld	ra,40(sp)
    800026da:	7402                	ld	s0,32(sp)
    800026dc:	64e2                	ld	s1,24(sp)
    800026de:	6942                	ld	s2,16(sp)
    800026e0:	69a2                	ld	s3,8(sp)
    800026e2:	6a02                	ld	s4,0(sp)
    800026e4:	6145                	addi	sp,sp,48
    800026e6:	8082                	ret
    memmove((char *)dst, src, len);
    800026e8:	000a061b          	sext.w	a2,s4
    800026ec:	85ce                	mv	a1,s3
    800026ee:	854a                	mv	a0,s2
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	63e080e7          	jalr	1598(ra) # 80000d2e <memmove>
    return 0;
    800026f8:	8526                	mv	a0,s1
    800026fa:	bff9                	j	800026d8 <either_copyout+0x32>

00000000800026fc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026fc:	7179                	addi	sp,sp,-48
    800026fe:	f406                	sd	ra,40(sp)
    80002700:	f022                	sd	s0,32(sp)
    80002702:	ec26                	sd	s1,24(sp)
    80002704:	e84a                	sd	s2,16(sp)
    80002706:	e44e                	sd	s3,8(sp)
    80002708:	e052                	sd	s4,0(sp)
    8000270a:	1800                	addi	s0,sp,48
    8000270c:	892a                	mv	s2,a0
    8000270e:	84ae                	mv	s1,a1
    80002710:	89b2                	mv	s3,a2
    80002712:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	37e080e7          	jalr	894(ra) # 80001a92 <myproc>
  if (user_src)
    8000271c:	c08d                	beqz	s1,8000273e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000271e:	86d2                	mv	a3,s4
    80002720:	864e                	mv	a2,s3
    80002722:	85ca                	mv	a1,s2
    80002724:	6d28                	ld	a0,88(a0)
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	fce080e7          	jalr	-50(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000272e:	70a2                	ld	ra,40(sp)
    80002730:	7402                	ld	s0,32(sp)
    80002732:	64e2                	ld	s1,24(sp)
    80002734:	6942                	ld	s2,16(sp)
    80002736:	69a2                	ld	s3,8(sp)
    80002738:	6a02                	ld	s4,0(sp)
    8000273a:	6145                	addi	sp,sp,48
    8000273c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000273e:	000a061b          	sext.w	a2,s4
    80002742:	85ce                	mv	a1,s3
    80002744:	854a                	mv	a0,s2
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	5e8080e7          	jalr	1512(ra) # 80000d2e <memmove>
    return 0;
    8000274e:	8526                	mv	a0,s1
    80002750:	bff9                	j	8000272e <either_copyin+0x32>

0000000080002752 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002752:	715d                	addi	sp,sp,-80
    80002754:	e486                	sd	ra,72(sp)
    80002756:	e0a2                	sd	s0,64(sp)
    80002758:	fc26                	sd	s1,56(sp)
    8000275a:	f84a                	sd	s2,48(sp)
    8000275c:	f44e                	sd	s3,40(sp)
    8000275e:	f052                	sd	s4,32(sp)
    80002760:	ec56                	sd	s5,24(sp)
    80002762:	e85a                	sd	s6,16(sp)
    80002764:	e45e                	sd	s7,8(sp)
    80002766:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002768:	00006517          	auipc	a0,0x6
    8000276c:	96050513          	addi	a0,a0,-1696 # 800080c8 <digits+0x88>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	e18080e7          	jalr	-488(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002778:	0000f497          	auipc	s1,0xf
    8000277c:	97848493          	addi	s1,s1,-1672 # 800110f0 <proc+0x160>
    80002780:	00016917          	auipc	s2,0x16
    80002784:	57090913          	addi	s2,s2,1392 # 80018cf0 <mlfq+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002788:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000278a:	00006997          	auipc	s3,0x6
    8000278e:	afe98993          	addi	s3,s3,-1282 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002792:	00006a97          	auipc	s5,0x6
    80002796:	afea8a93          	addi	s5,s5,-1282 # 80008290 <digits+0x250>
    printf("\n");
    8000279a:	00006a17          	auipc	s4,0x6
    8000279e:	92ea0a13          	addi	s4,s4,-1746 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a2:	00006b97          	auipc	s7,0x6
    800027a6:	b2eb8b93          	addi	s7,s7,-1234 # 800082d0 <states.0>
    800027aa:	a00d                	j	800027cc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027ac:	ed06a583          	lw	a1,-304(a3)
    800027b0:	8556                	mv	a0,s5
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	dd6080e7          	jalr	-554(ra) # 80000588 <printf>
    printf("\n");
    800027ba:	8552                	mv	a0,s4
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	dcc080e7          	jalr	-564(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027c4:	1f048493          	addi	s1,s1,496
    800027c8:	03248163          	beq	s1,s2,800027ea <procdump+0x98>
    if (p->state == UNUSED)
    800027cc:	86a6                	mv	a3,s1
    800027ce:	eb84a783          	lw	a5,-328(s1)
    800027d2:	dbed                	beqz	a5,800027c4 <procdump+0x72>
      state = "???";
    800027d4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d6:	fcfb6be3          	bltu	s6,a5,800027ac <procdump+0x5a>
    800027da:	1782                	slli	a5,a5,0x20
    800027dc:	9381                	srli	a5,a5,0x20
    800027de:	078e                	slli	a5,a5,0x3
    800027e0:	97de                	add	a5,a5,s7
    800027e2:	6390                	ld	a2,0(a5)
    800027e4:	f661                	bnez	a2,800027ac <procdump+0x5a>
      state = "???";
    800027e6:	864e                	mv	a2,s3
    800027e8:	b7d1                	j	800027ac <procdump+0x5a>
  }
}
    800027ea:	60a6                	ld	ra,72(sp)
    800027ec:	6406                	ld	s0,64(sp)
    800027ee:	74e2                	ld	s1,56(sp)
    800027f0:	7942                	ld	s2,48(sp)
    800027f2:	79a2                	ld	s3,40(sp)
    800027f4:	7a02                	ld	s4,32(sp)
    800027f6:	6ae2                	ld	s5,24(sp)
    800027f8:	6b42                	ld	s6,16(sp)
    800027fa:	6ba2                	ld	s7,8(sp)
    800027fc:	6161                	addi	sp,sp,80
    800027fe:	8082                	ret

0000000080002800 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002800:	711d                	addi	sp,sp,-96
    80002802:	ec86                	sd	ra,88(sp)
    80002804:	e8a2                	sd	s0,80(sp)
    80002806:	e4a6                	sd	s1,72(sp)
    80002808:	e0ca                	sd	s2,64(sp)
    8000280a:	fc4e                	sd	s3,56(sp)
    8000280c:	f852                	sd	s4,48(sp)
    8000280e:	f456                	sd	s5,40(sp)
    80002810:	f05a                	sd	s6,32(sp)
    80002812:	ec5e                	sd	s7,24(sp)
    80002814:	e862                	sd	s8,16(sp)
    80002816:	e466                	sd	s9,8(sp)
    80002818:	e06a                	sd	s10,0(sp)
    8000281a:	1080                	addi	s0,sp,96
    8000281c:	8b2a                	mv	s6,a0
    8000281e:	8bae                	mv	s7,a1
    80002820:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	270080e7          	jalr	624(ra) # 80001a92 <myproc>
    8000282a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000282c:	0000e517          	auipc	a0,0xe
    80002830:	34c50513          	addi	a0,a0,844 # 80010b78 <wait_lock>
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	3a2080e7          	jalr	930(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000283c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000283e:	4a15                	li	s4,5
        havekids = 1;
    80002840:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002842:	00016997          	auipc	s3,0x16
    80002846:	34e98993          	addi	s3,s3,846 # 80018b90 <mlfq>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000284a:	0000ed17          	auipc	s10,0xe
    8000284e:	32ed0d13          	addi	s10,s10,814 # 80010b78 <wait_lock>
    havekids = 0;
    80002852:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002854:	0000e497          	auipc	s1,0xe
    80002858:	73c48493          	addi	s1,s1,1852 # 80010f90 <proc>
    8000285c:	a059                	j	800028e2 <waitx+0xe2>
          pid = np->pid;
    8000285e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002862:	1704a703          	lw	a4,368(s1)
    80002866:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000286a:	1744a783          	lw	a5,372(s1)
    8000286e:	9f3d                	addw	a4,a4,a5
    80002870:	1784a783          	lw	a5,376(s1)
    80002874:	9f99                	subw	a5,a5,a4
    80002876:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000287a:	000b0e63          	beqz	s6,80002896 <waitx+0x96>
    8000287e:	4691                	li	a3,4
    80002880:	02c48613          	addi	a2,s1,44
    80002884:	85da                	mv	a1,s6
    80002886:	05893503          	ld	a0,88(s2)
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	dde080e7          	jalr	-546(ra) # 80001668 <copyout>
    80002892:	02054563          	bltz	a0,800028bc <waitx+0xbc>
          freeproc(np);
    80002896:	8526                	mv	a0,s1
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	3ac080e7          	jalr	940(ra) # 80001c44 <freeproc>
          release(&np->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	3e8080e7          	jalr	1000(ra) # 80000c8a <release>
          release(&wait_lock);
    800028aa:	0000e517          	auipc	a0,0xe
    800028ae:	2ce50513          	addi	a0,a0,718 # 80010b78 <wait_lock>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	3d8080e7          	jalr	984(ra) # 80000c8a <release>
          return pid;
    800028ba:	a09d                	j	80002920 <waitx+0x120>
            release(&np->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	3cc080e7          	jalr	972(ra) # 80000c8a <release>
            release(&wait_lock);
    800028c6:	0000e517          	auipc	a0,0xe
    800028ca:	2b250513          	addi	a0,a0,690 # 80010b78 <wait_lock>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	3bc080e7          	jalr	956(ra) # 80000c8a <release>
            return -1;
    800028d6:	59fd                	li	s3,-1
    800028d8:	a0a1                	j	80002920 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800028da:	1f048493          	addi	s1,s1,496
    800028de:	03348463          	beq	s1,s3,80002906 <waitx+0x106>
      if (np->parent == p)
    800028e2:	7c9c                	ld	a5,56(s1)
    800028e4:	ff279be3          	bne	a5,s2,800028da <waitx+0xda>
        acquire(&np->lock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	2ec080e7          	jalr	748(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800028f2:	4c9c                	lw	a5,24(s1)
    800028f4:	f74785e3          	beq	a5,s4,8000285e <waitx+0x5e>
        release(&np->lock);
    800028f8:	8526                	mv	a0,s1
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	390080e7          	jalr	912(ra) # 80000c8a <release>
        havekids = 1;
    80002902:	8756                	mv	a4,s5
    80002904:	bfd9                	j	800028da <waitx+0xda>
    if (!havekids || p->killed)
    80002906:	c701                	beqz	a4,8000290e <waitx+0x10e>
    80002908:	02892783          	lw	a5,40(s2)
    8000290c:	cb8d                	beqz	a5,8000293e <waitx+0x13e>
      release(&wait_lock);
    8000290e:	0000e517          	auipc	a0,0xe
    80002912:	26a50513          	addi	a0,a0,618 # 80010b78 <wait_lock>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	374080e7          	jalr	884(ra) # 80000c8a <release>
      return -1;
    8000291e:	59fd                	li	s3,-1
  }
}
    80002920:	854e                	mv	a0,s3
    80002922:	60e6                	ld	ra,88(sp)
    80002924:	6446                	ld	s0,80(sp)
    80002926:	64a6                	ld	s1,72(sp)
    80002928:	6906                	ld	s2,64(sp)
    8000292a:	79e2                	ld	s3,56(sp)
    8000292c:	7a42                	ld	s4,48(sp)
    8000292e:	7aa2                	ld	s5,40(sp)
    80002930:	7b02                	ld	s6,32(sp)
    80002932:	6be2                	ld	s7,24(sp)
    80002934:	6c42                	ld	s8,16(sp)
    80002936:	6ca2                	ld	s9,8(sp)
    80002938:	6d02                	ld	s10,0(sp)
    8000293a:	6125                	addi	sp,sp,96
    8000293c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000293e:	85ea                	mv	a1,s10
    80002940:	854a                	mv	a0,s2
    80002942:	00000097          	auipc	ra,0x0
    80002946:	950080e7          	jalr	-1712(ra) # 80002292 <sleep>
    havekids = 0;
    8000294a:	b721                	j	80002852 <waitx+0x52>

000000008000294c <update_time>:


void update_time()
{
    8000294c:	7179                	addi	sp,sp,-48
    8000294e:	f406                	sd	ra,40(sp)
    80002950:	f022                	sd	s0,32(sp)
    80002952:	ec26                	sd	s1,24(sp)
    80002954:	e84a                	sd	s2,16(sp)
    80002956:	e44e                	sd	s3,8(sp)
    80002958:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000295a:	0000e497          	auipc	s1,0xe
    8000295e:	63648493          	addi	s1,s1,1590 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002962:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002964:	00016917          	auipc	s2,0x16
    80002968:	22c90913          	addi	s2,s2,556 # 80018b90 <mlfq>
    8000296c:	a811                	j	80002980 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000296e:	8526                	mv	a0,s1
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	31a080e7          	jalr	794(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002978:	1f048493          	addi	s1,s1,496
    8000297c:	03248063          	beq	s1,s2,8000299c <update_time+0x50>
    acquire(&p->lock);
    80002980:	8526                	mv	a0,s1
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	254080e7          	jalr	596(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000298a:	4c9c                	lw	a5,24(s1)
    8000298c:	ff3791e3          	bne	a5,s3,8000296e <update_time+0x22>
      p->rtime++;
    80002990:	1704a783          	lw	a5,368(s1)
    80002994:	2785                	addiw	a5,a5,1
    80002996:	16f4a823          	sw	a5,368(s1)
    8000299a:	bfd1                	j	8000296e <update_time+0x22>
  }
    8000299c:	70a2                	ld	ra,40(sp)
    8000299e:	7402                	ld	s0,32(sp)
    800029a0:	64e2                	ld	s1,24(sp)
    800029a2:	6942                	ld	s2,16(sp)
    800029a4:	69a2                	ld	s3,8(sp)
    800029a6:	6145                	addi	sp,sp,48
    800029a8:	8082                	ret

00000000800029aa <swtch>:
    800029aa:	00153023          	sd	ra,0(a0)
    800029ae:	00253423          	sd	sp,8(a0)
    800029b2:	e900                	sd	s0,16(a0)
    800029b4:	ed04                	sd	s1,24(a0)
    800029b6:	03253023          	sd	s2,32(a0)
    800029ba:	03353423          	sd	s3,40(a0)
    800029be:	03453823          	sd	s4,48(a0)
    800029c2:	03553c23          	sd	s5,56(a0)
    800029c6:	05653023          	sd	s6,64(a0)
    800029ca:	05753423          	sd	s7,72(a0)
    800029ce:	05853823          	sd	s8,80(a0)
    800029d2:	05953c23          	sd	s9,88(a0)
    800029d6:	07a53023          	sd	s10,96(a0)
    800029da:	07b53423          	sd	s11,104(a0)
    800029de:	0005b083          	ld	ra,0(a1)
    800029e2:	0085b103          	ld	sp,8(a1)
    800029e6:	6980                	ld	s0,16(a1)
    800029e8:	6d84                	ld	s1,24(a1)
    800029ea:	0205b903          	ld	s2,32(a1)
    800029ee:	0285b983          	ld	s3,40(a1)
    800029f2:	0305ba03          	ld	s4,48(a1)
    800029f6:	0385ba83          	ld	s5,56(a1)
    800029fa:	0405bb03          	ld	s6,64(a1)
    800029fe:	0485bb83          	ld	s7,72(a1)
    80002a02:	0505bc03          	ld	s8,80(a1)
    80002a06:	0585bc83          	ld	s9,88(a1)
    80002a0a:	0605bd03          	ld	s10,96(a1)
    80002a0e:	0685bd83          	ld	s11,104(a1)
    80002a12:	8082                	ret

0000000080002a14 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a14:	1141                	addi	sp,sp,-16
    80002a16:	e406                	sd	ra,8(sp)
    80002a18:	e022                	sd	s0,0(sp)
    80002a1a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a1c:	00006597          	auipc	a1,0x6
    80002a20:	8e458593          	addi	a1,a1,-1820 # 80008300 <states.0+0x30>
    80002a24:	00017517          	auipc	a0,0x17
    80002a28:	98c50513          	addi	a0,a0,-1652 # 800193b0 <tickslock>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	11a080e7          	jalr	282(ra) # 80000b46 <initlock>
}
    80002a34:	60a2                	ld	ra,8(sp)
    80002a36:	6402                	ld	s0,0(sp)
    80002a38:	0141                	addi	sp,sp,16
    80002a3a:	8082                	ret

0000000080002a3c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a3c:	1141                	addi	sp,sp,-16
    80002a3e:	e422                	sd	s0,8(sp)
    80002a40:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a42:	00003797          	auipc	a5,0x3
    80002a46:	6de78793          	addi	a5,a5,1758 # 80006120 <kernelvec>
    80002a4a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a4e:	6422                	ld	s0,8(sp)
    80002a50:	0141                	addi	sp,sp,16
    80002a52:	8082                	ret

0000000080002a54 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a54:	1141                	addi	sp,sp,-16
    80002a56:	e406                	sd	ra,8(sp)
    80002a58:	e022                	sd	s0,0(sp)
    80002a5a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	036080e7          	jalr	54(ra) # 80001a92 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a68:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a6e:	00004617          	auipc	a2,0x4
    80002a72:	59260613          	addi	a2,a2,1426 # 80007000 <_trampoline>
    80002a76:	00004697          	auipc	a3,0x4
    80002a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80002a7e:	8e91                	sub	a3,a3,a2
    80002a80:	040007b7          	lui	a5,0x4000
    80002a84:	17fd                	addi	a5,a5,-1
    80002a86:	07b2                	slli	a5,a5,0xc
    80002a88:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a8a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a8e:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a90:	180026f3          	csrr	a3,satp
    80002a94:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a96:	7138                	ld	a4,96(a0)
    80002a98:	6534                	ld	a3,72(a0)
    80002a9a:	6585                	lui	a1,0x1
    80002a9c:	96ae                	add	a3,a3,a1
    80002a9e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002aa0:	7138                	ld	a4,96(a0)
    80002aa2:	00000697          	auipc	a3,0x0
    80002aa6:	13e68693          	addi	a3,a3,318 # 80002be0 <usertrap>
    80002aaa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002aac:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002aae:	8692                	mv	a3,tp
    80002ab0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ab6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002aba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abe:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ac2:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac4:	6f18                	ld	a4,24(a4)
    80002ac6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aca:	6d28                	ld	a0,88(a0)
    80002acc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ace:	00004717          	auipc	a4,0x4
    80002ad2:	5ce70713          	addi	a4,a4,1486 # 8000709c <userret>
    80002ad6:	8f11                	sub	a4,a4,a2
    80002ad8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ada:	577d                	li	a4,-1
    80002adc:	177e                	slli	a4,a4,0x3f
    80002ade:	8d59                	or	a0,a0,a4
    80002ae0:	9782                	jalr	a5
}
    80002ae2:	60a2                	ld	ra,8(sp)
    80002ae4:	6402                	ld	s0,0(sp)
    80002ae6:	0141                	addi	sp,sp,16
    80002ae8:	8082                	ret

0000000080002aea <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002aea:	1101                	addi	sp,sp,-32
    80002aec:	ec06                	sd	ra,24(sp)
    80002aee:	e822                	sd	s0,16(sp)
    80002af0:	e426                	sd	s1,8(sp)
    80002af2:	e04a                	sd	s2,0(sp)
    80002af4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002af6:	00017917          	auipc	s2,0x17
    80002afa:	8ba90913          	addi	s2,s2,-1862 # 800193b0 <tickslock>
    80002afe:	854a                	mv	a0,s2
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	0d6080e7          	jalr	214(ra) # 80000bd6 <acquire>
  ticks++;
    80002b08:	00006497          	auipc	s1,0x6
    80002b0c:	de848493          	addi	s1,s1,-536 # 800088f0 <ticks>
    80002b10:	409c                	lw	a5,0(s1)
    80002b12:	2785                	addiw	a5,a5,1
    80002b14:	c09c                	sw	a5,0(s1)
  update_time();
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	e36080e7          	jalr	-458(ra) # 8000294c <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b1e:	8526                	mv	a0,s1
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	7d6080e7          	jalr	2006(ra) # 800022f6 <wakeup>
  release(&tickslock);
    80002b28:	854a                	mv	a0,s2
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	160080e7          	jalr	352(ra) # 80000c8a <release>
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6902                	ld	s2,0(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret

0000000080002b3e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b48:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b4c:	00074d63          	bltz	a4,80002b66 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b50:	57fd                	li	a5,-1
    80002b52:	17fe                	slli	a5,a5,0x3f
    80002b54:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b56:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b58:	06f70363          	beq	a4,a5,80002bbe <devintr+0x80>
  }
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	64a2                	ld	s1,8(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret
      (scause & 0xff) == 9)
    80002b66:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002b6a:	46a5                	li	a3,9
    80002b6c:	fed792e3          	bne	a5,a3,80002b50 <devintr+0x12>
    int irq = plic_claim();
    80002b70:	00003097          	auipc	ra,0x3
    80002b74:	6b8080e7          	jalr	1720(ra) # 80006228 <plic_claim>
    80002b78:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b7a:	47a9                	li	a5,10
    80002b7c:	02f50763          	beq	a0,a5,80002baa <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002b80:	4785                	li	a5,1
    80002b82:	02f50963          	beq	a0,a5,80002bb4 <devintr+0x76>
    return 1;
    80002b86:	4505                	li	a0,1
    else if (irq)
    80002b88:	d8f1                	beqz	s1,80002b5c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b8a:	85a6                	mv	a1,s1
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	77c50513          	addi	a0,a0,1916 # 80008308 <states.0+0x38>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f4080e7          	jalr	-1548(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	00003097          	auipc	ra,0x3
    80002ba2:	6ae080e7          	jalr	1710(ra) # 8000624c <plic_complete>
    return 1;
    80002ba6:	4505                	li	a0,1
    80002ba8:	bf55                	j	80002b5c <devintr+0x1e>
      uartintr();
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	df0080e7          	jalr	-528(ra) # 8000099a <uartintr>
    80002bb2:	b7ed                	j	80002b9c <devintr+0x5e>
      virtio_disk_intr();
    80002bb4:	00004097          	auipc	ra,0x4
    80002bb8:	b64080e7          	jalr	-1180(ra) # 80006718 <virtio_disk_intr>
    80002bbc:	b7c5                	j	80002b9c <devintr+0x5e>
    if (cpuid() == 0)
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	ea8080e7          	jalr	-344(ra) # 80001a66 <cpuid>
    80002bc6:	c901                	beqz	a0,80002bd6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bc8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bce:	14479073          	csrw	sip,a5
    return 2;
    80002bd2:	4509                	li	a0,2
    80002bd4:	b761                	j	80002b5c <devintr+0x1e>
      clockintr();
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f14080e7          	jalr	-236(ra) # 80002aea <clockintr>
    80002bde:	b7ed                	j	80002bc8 <devintr+0x8a>

0000000080002be0 <usertrap>:
{
    80002be0:	1101                	addi	sp,sp,-32
    80002be2:	ec06                	sd	ra,24(sp)
    80002be4:	e822                	sd	s0,16(sp)
    80002be6:	e426                	sd	s1,8(sp)
    80002be8:	e04a                	sd	s2,0(sp)
    80002bea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bec:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002bf0:	1007f793          	andi	a5,a5,256
    80002bf4:	e3b1                	bnez	a5,80002c38 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf6:	00003797          	auipc	a5,0x3
    80002bfa:	52a78793          	addi	a5,a5,1322 # 80006120 <kernelvec>
    80002bfe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	e90080e7          	jalr	-368(ra) # 80001a92 <myproc>
    80002c0a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c0c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0e:	14102773          	csrr	a4,sepc
    80002c12:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c14:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c18:	47a1                	li	a5,8
    80002c1a:	02f70763          	beq	a4,a5,80002c48 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	f20080e7          	jalr	-224(ra) # 80002b3e <devintr>
    80002c26:	892a                	mv	s2,a0
    80002c28:	c92d                	beqz	a0,80002c9a <usertrap+0xba>
  if (killed(p))
    80002c2a:	8526                	mv	a0,s1
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	91a080e7          	jalr	-1766(ra) # 80002546 <killed>
    80002c34:	c555                	beqz	a0,80002ce0 <usertrap+0x100>
    80002c36:	a045                	j	80002cd6 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	6f050513          	addi	a0,a0,1776 # 80008328 <states.0+0x58>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	8fe080e7          	jalr	-1794(ra) # 8000053e <panic>
    if (killed(p))
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	8fe080e7          	jalr	-1794(ra) # 80002546 <killed>
    80002c50:	ed1d                	bnez	a0,80002c8e <usertrap+0xae>
    p->trapframe->epc += 4;
    80002c52:	70b8                	ld	a4,96(s1)
    80002c54:	6f1c                	ld	a5,24(a4)
    80002c56:	0791                	addi	a5,a5,4
    80002c58:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c62:	10079073          	csrw	sstatus,a5
    syscall();
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	338080e7          	jalr	824(ra) # 80002f9e <syscall>
  if (killed(p))
    80002c6e:	8526                	mv	a0,s1
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	8d6080e7          	jalr	-1834(ra) # 80002546 <killed>
    80002c78:	ed31                	bnez	a0,80002cd4 <usertrap+0xf4>
  usertrapret();
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	dda080e7          	jalr	-550(ra) # 80002a54 <usertrapret>
}
    80002c82:	60e2                	ld	ra,24(sp)
    80002c84:	6442                	ld	s0,16(sp)
    80002c86:	64a2                	ld	s1,8(sp)
    80002c88:	6902                	ld	s2,0(sp)
    80002c8a:	6105                	addi	sp,sp,32
    80002c8c:	8082                	ret
      exit(-1);
    80002c8e:	557d                	li	a0,-1
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	736080e7          	jalr	1846(ra) # 800023c6 <exit>
    80002c98:	bf6d                	j	80002c52 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c9a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c9e:	5890                	lw	a2,48(s1)
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	6a850513          	addi	a0,a0,1704 # 80008348 <states.0+0x78>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	8e0080e7          	jalr	-1824(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cb4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb8:	00005517          	auipc	a0,0x5
    80002cbc:	6c050513          	addi	a0,a0,1728 # 80008378 <states.0+0xa8>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	8c8080e7          	jalr	-1848(ra) # 80000588 <printf>
    setkilled(p);
    80002cc8:	8526                	mv	a0,s1
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	850080e7          	jalr	-1968(ra) # 8000251a <setkilled>
    80002cd2:	bf71                	j	80002c6e <usertrap+0x8e>
  if (killed(p))
    80002cd4:	4901                	li	s2,0
    exit(-1);
    80002cd6:	557d                	li	a0,-1
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	6ee080e7          	jalr	1774(ra) # 800023c6 <exit>
  if (which_dev == 2)
    80002ce0:	4789                	li	a5,2
    80002ce2:	f8f91ce3          	bne	s2,a5,80002c7a <usertrap+0x9a>
      if(p->ticks){
    80002ce6:	1cc4a703          	lw	a4,460(s1)
    80002cea:	cf19                	beqz	a4,80002d08 <usertrap+0x128>
      p->cur_ticks ++;
    80002cec:	1d04a783          	lw	a5,464(s1)
    80002cf0:	2785                	addiw	a5,a5,1
    80002cf2:	0007869b          	sext.w	a3,a5
    80002cf6:	1cf4a823          	sw	a5,464(s1)
      if(p->alarm_on==0 && p->ticks >0 && p->cur_ticks>=p->ticks){
    80002cfa:	1e04a783          	lw	a5,480(s1)
    80002cfe:	e789                	bnez	a5,80002d08 <usertrap+0x128>
    80002d00:	00e05463          	blez	a4,80002d08 <usertrap+0x128>
    80002d04:	02e6d263          	bge	a3,a4,80002d28 <usertrap+0x148>
if(p->change_queue<1 && p->queue_level !=3){
    80002d08:	1c44a783          	lw	a5,452(s1)
    80002d0c:	eb89                	bnez	a5,80002d1e <usertrap+0x13e>
    80002d0e:	1bc4a783          	lw	a5,444(s1)
    80002d12:	470d                	li	a4,3
    80002d14:	00e78563          	beq	a5,a4,80002d1e <usertrap+0x13e>
    p->queue_level=p->queue_level+1;
    80002d18:	2785                	addiw	a5,a5,1
    80002d1a:	1af4ae23          	sw	a5,444(s1)
    yield();
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	538080e7          	jalr	1336(ra) # 80002256 <yield>
    80002d26:	bf91                	j	80002c7a <usertrap+0x9a>
        p->cur_ticks=0;
    80002d28:	1c04a823          	sw	zero,464(s1)
        p->alarm_on=1;
    80002d2c:	4785                	li	a5,1
    80002d2e:	1ef4a023          	sw	a5,480(s1)
        p->alarm_tf=kalloc();
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	db4080e7          	jalr	-588(ra) # 80000ae6 <kalloc>
    80002d3a:	1ca4bc23          	sd	a0,472(s1)
      memmove(p->alarm_tf, p->trapframe, PGSIZE);
    80002d3e:	6605                	lui	a2,0x1
    80002d40:	70ac                	ld	a1,96(s1)
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	fec080e7          	jalr	-20(ra) # 80000d2e <memmove>
        p->trapframe->epc = p->handler;
    80002d4a:	70bc                	ld	a5,96(s1)
    80002d4c:	1e84b703          	ld	a4,488(s1)
    80002d50:	ef98                	sd	a4,24(a5)
    80002d52:	bf5d                	j	80002d08 <usertrap+0x128>

0000000080002d54 <kerneltrap>:
{
    80002d54:	7179                	addi	sp,sp,-48
    80002d56:	f406                	sd	ra,40(sp)
    80002d58:	f022                	sd	s0,32(sp)
    80002d5a:	ec26                	sd	s1,24(sp)
    80002d5c:	e84a                	sd	s2,16(sp)
    80002d5e:	e44e                	sd	s3,8(sp)
    80002d60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d62:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d6a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d6e:	1004f793          	andi	a5,s1,256
    80002d72:	cb85                	beqz	a5,80002da2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d78:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002d7a:	ef85                	bnez	a5,80002db2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	dc2080e7          	jalr	-574(ra) # 80002b3e <devintr>
    80002d84:	cd1d                	beqz	a0,80002dc2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d86:	4789                	li	a5,2
    80002d88:	06f50a63          	beq	a0,a5,80002dfc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d8c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d90:	10049073          	csrw	sstatus,s1
}
    80002d94:	70a2                	ld	ra,40(sp)
    80002d96:	7402                	ld	s0,32(sp)
    80002d98:	64e2                	ld	s1,24(sp)
    80002d9a:	6942                	ld	s2,16(sp)
    80002d9c:	69a2                	ld	s3,8(sp)
    80002d9e:	6145                	addi	sp,sp,48
    80002da0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	5f650513          	addi	a0,a0,1526 # 80008398 <states.0+0xc8>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002db2:	00005517          	auipc	a0,0x5
    80002db6:	60e50513          	addi	a0,a0,1550 # 800083c0 <states.0+0xf0>
    80002dba:	ffffd097          	auipc	ra,0xffffd
    80002dbe:	784080e7          	jalr	1924(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dc2:	85ce                	mv	a1,s3
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	61c50513          	addi	a0,a0,1564 # 800083e0 <states.0+0x110>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	7bc080e7          	jalr	1980(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ddc:	00005517          	auipc	a0,0x5
    80002de0:	61450513          	addi	a0,a0,1556 # 800083f0 <states.0+0x120>
    80002de4:	ffffd097          	auipc	ra,0xffffd
    80002de8:	7a4080e7          	jalr	1956(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002dec:	00005517          	auipc	a0,0x5
    80002df0:	61c50513          	addi	a0,a0,1564 # 80008408 <states.0+0x138>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	c96080e7          	jalr	-874(ra) # 80001a92 <myproc>
    80002e04:	d541                	beqz	a0,80002d8c <kerneltrap+0x38>
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	c8c080e7          	jalr	-884(ra) # 80001a92 <myproc>
    80002e0e:	4d18                	lw	a4,24(a0)
    80002e10:	4791                	li	a5,4
    80002e12:	f6f71de3          	bne	a4,a5,80002d8c <kerneltrap+0x38>
  yield();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	440080e7          	jalr	1088(ra) # 80002256 <yield>
    80002e1e:	b7bd                	j	80002d8c <kerneltrap+0x38>

0000000080002e20 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
    80002e2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	c66080e7          	jalr	-922(ra) # 80001a92 <myproc>
  switch (n) {
    80002e34:	4795                	li	a5,5
    80002e36:	0497e163          	bltu	a5,s1,80002e78 <argraw+0x58>
    80002e3a:	048a                	slli	s1,s1,0x2
    80002e3c:	00005717          	auipc	a4,0x5
    80002e40:	60470713          	addi	a4,a4,1540 # 80008440 <states.0+0x170>
    80002e44:	94ba                	add	s1,s1,a4
    80002e46:	409c                	lw	a5,0(s1)
    80002e48:	97ba                	add	a5,a5,a4
    80002e4a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e4c:	713c                	ld	a5,96(a0)
    80002e4e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret
    return p->trapframe->a1;
    80002e5a:	713c                	ld	a5,96(a0)
    80002e5c:	7fa8                	ld	a0,120(a5)
    80002e5e:	bfcd                	j	80002e50 <argraw+0x30>
    return p->trapframe->a2;
    80002e60:	713c                	ld	a5,96(a0)
    80002e62:	63c8                	ld	a0,128(a5)
    80002e64:	b7f5                	j	80002e50 <argraw+0x30>
    return p->trapframe->a3;
    80002e66:	713c                	ld	a5,96(a0)
    80002e68:	67c8                	ld	a0,136(a5)
    80002e6a:	b7dd                	j	80002e50 <argraw+0x30>
    return p->trapframe->a4;
    80002e6c:	713c                	ld	a5,96(a0)
    80002e6e:	6bc8                	ld	a0,144(a5)
    80002e70:	b7c5                	j	80002e50 <argraw+0x30>
    return p->trapframe->a5;
    80002e72:	713c                	ld	a5,96(a0)
    80002e74:	6fc8                	ld	a0,152(a5)
    80002e76:	bfe9                	j	80002e50 <argraw+0x30>
  panic("argraw");
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	5a050513          	addi	a0,a0,1440 # 80008418 <states.0+0x148>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	6be080e7          	jalr	1726(ra) # 8000053e <panic>

0000000080002e88 <fetchaddr>:
{
    80002e88:	1101                	addi	sp,sp,-32
    80002e8a:	ec06                	sd	ra,24(sp)
    80002e8c:	e822                	sd	s0,16(sp)
    80002e8e:	e426                	sd	s1,8(sp)
    80002e90:	e04a                	sd	s2,0(sp)
    80002e92:	1000                	addi	s0,sp,32
    80002e94:	84aa                	mv	s1,a0
    80002e96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	bfa080e7          	jalr	-1030(ra) # 80001a92 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ea0:	693c                	ld	a5,80(a0)
    80002ea2:	02f4f863          	bgeu	s1,a5,80002ed2 <fetchaddr+0x4a>
    80002ea6:	00848713          	addi	a4,s1,8
    80002eaa:	02e7e663          	bltu	a5,a4,80002ed6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002eae:	46a1                	li	a3,8
    80002eb0:	8626                	mv	a2,s1
    80002eb2:	85ca                	mv	a1,s2
    80002eb4:	6d28                	ld	a0,88(a0)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	83e080e7          	jalr	-1986(ra) # 800016f4 <copyin>
    80002ebe:	00a03533          	snez	a0,a0
    80002ec2:	40a00533          	neg	a0,a0
}
    80002ec6:	60e2                	ld	ra,24(sp)
    80002ec8:	6442                	ld	s0,16(sp)
    80002eca:	64a2                	ld	s1,8(sp)
    80002ecc:	6902                	ld	s2,0(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret
    return -1;
    80002ed2:	557d                	li	a0,-1
    80002ed4:	bfcd                	j	80002ec6 <fetchaddr+0x3e>
    80002ed6:	557d                	li	a0,-1
    80002ed8:	b7fd                	j	80002ec6 <fetchaddr+0x3e>

0000000080002eda <fetchstr>:
{
    80002eda:	7179                	addi	sp,sp,-48
    80002edc:	f406                	sd	ra,40(sp)
    80002ede:	f022                	sd	s0,32(sp)
    80002ee0:	ec26                	sd	s1,24(sp)
    80002ee2:	e84a                	sd	s2,16(sp)
    80002ee4:	e44e                	sd	s3,8(sp)
    80002ee6:	1800                	addi	s0,sp,48
    80002ee8:	892a                	mv	s2,a0
    80002eea:	84ae                	mv	s1,a1
    80002eec:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	ba4080e7          	jalr	-1116(ra) # 80001a92 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ef6:	86ce                	mv	a3,s3
    80002ef8:	864a                	mv	a2,s2
    80002efa:	85a6                	mv	a1,s1
    80002efc:	6d28                	ld	a0,88(a0)
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	884080e7          	jalr	-1916(ra) # 80001782 <copyinstr>
    80002f06:	00054e63          	bltz	a0,80002f22 <fetchstr+0x48>
  return strlen(buf);
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	f42080e7          	jalr	-190(ra) # 80000e4e <strlen>
}
    80002f14:	70a2                	ld	ra,40(sp)
    80002f16:	7402                	ld	s0,32(sp)
    80002f18:	64e2                	ld	s1,24(sp)
    80002f1a:	6942                	ld	s2,16(sp)
    80002f1c:	69a2                	ld	s3,8(sp)
    80002f1e:	6145                	addi	sp,sp,48
    80002f20:	8082                	ret
    return -1;
    80002f22:	557d                	li	a0,-1
    80002f24:	bfc5                	j	80002f14 <fetchstr+0x3a>

0000000080002f26 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	1000                	addi	s0,sp,32
    80002f30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f32:	00000097          	auipc	ra,0x0
    80002f36:	eee080e7          	jalr	-274(ra) # 80002e20 <argraw>
    80002f3a:	c088                	sw	a0,0(s1)
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	64a2                	ld	s1,8(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	e426                	sd	s1,8(sp)
    80002f4e:	1000                	addi	s0,sp,32
    80002f50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	ece080e7          	jalr	-306(ra) # 80002e20 <argraw>
    80002f5a:	e088                	sd	a0,0(s1)
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret

0000000080002f66 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f66:	7179                	addi	sp,sp,-48
    80002f68:	f406                	sd	ra,40(sp)
    80002f6a:	f022                	sd	s0,32(sp)
    80002f6c:	ec26                	sd	s1,24(sp)
    80002f6e:	e84a                	sd	s2,16(sp)
    80002f70:	1800                	addi	s0,sp,48
    80002f72:	84ae                	mv	s1,a1
    80002f74:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f76:	fd840593          	addi	a1,s0,-40
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	fcc080e7          	jalr	-52(ra) # 80002f46 <argaddr>
  return fetchstr(addr, buf, max);
    80002f82:	864a                	mv	a2,s2
    80002f84:	85a6                	mv	a1,s1
    80002f86:	fd843503          	ld	a0,-40(s0)
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	f50080e7          	jalr	-176(ra) # 80002eda <fetchstr>
}
    80002f92:	70a2                	ld	ra,40(sp)
    80002f94:	7402                	ld	s0,32(sp)
    80002f96:	64e2                	ld	s1,24(sp)
    80002f98:	6942                	ld	s2,16(sp)
    80002f9a:	6145                	addi	sp,sp,48
    80002f9c:	8082                	ret

0000000080002f9e <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002f9e:	1101                	addi	sp,sp,-32
    80002fa0:	ec06                	sd	ra,24(sp)
    80002fa2:	e822                	sd	s0,16(sp)
    80002fa4:	e426                	sd	s1,8(sp)
    80002fa6:	e04a                	sd	s2,0(sp)
    80002fa8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	ae8080e7          	jalr	-1304(ra) # 80001a92 <myproc>
    80002fb2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fb4:	06053903          	ld	s2,96(a0)
    80002fb8:	0a893783          	ld	a5,168(s2)
    80002fbc:	0007869b          	sext.w	a3,a5
   if (num==SYS_read){
    80002fc0:	4715                	li	a4,5
    80002fc2:	02e68663          	beq	a3,a4,80002fee <syscall+0x50>
    readcount++; //my change
  }
  if (num==SYS_getreadcount){
    80002fc6:	475d                	li	a4,23
    80002fc8:	04e69663          	bne	a3,a4,80003014 <syscall+0x76>
    p->readcallcount = readcount; //my change
    80002fcc:	00006717          	auipc	a4,0x6
    80002fd0:	92872703          	lw	a4,-1752(a4) # 800088f4 <readcount>
    80002fd4:	c138                	sw	a4,64(a0)
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fd6:	37fd                	addiw	a5,a5,-1
    80002fd8:	4661                	li	a2,24
    80002fda:	00000717          	auipc	a4,0x0
    80002fde:	3ae70713          	addi	a4,a4,942 # 80003388 <sys_getreadcount>
    80002fe2:	04f66663          	bltu	a2,a5,8000302e <syscall+0x90>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fe6:	9702                	jalr	a4
    80002fe8:	06a93823          	sd	a0,112(s2)
    80002fec:	a8b9                	j	8000304a <syscall+0xac>
    readcount++; //my change
    80002fee:	00006617          	auipc	a2,0x6
    80002ff2:	90660613          	addi	a2,a2,-1786 # 800088f4 <readcount>
    80002ff6:	4218                	lw	a4,0(a2)
    80002ff8:	2705                	addiw	a4,a4,1
    80002ffa:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ffc:	37fd                	addiw	a5,a5,-1
    80002ffe:	4761                	li	a4,24
    80003000:	02f76763          	bltu	a4,a5,8000302e <syscall+0x90>
    80003004:	068e                	slli	a3,a3,0x3
    80003006:	00005797          	auipc	a5,0x5
    8000300a:	45278793          	addi	a5,a5,1106 # 80008458 <syscalls>
    8000300e:	96be                	add	a3,a3,a5
    80003010:	6298                	ld	a4,0(a3)
    80003012:	bfd1                	j	80002fe6 <syscall+0x48>
    80003014:	37fd                	addiw	a5,a5,-1
    80003016:	4761                	li	a4,24
    80003018:	00f76b63          	bltu	a4,a5,8000302e <syscall+0x90>
    8000301c:	00369713          	slli	a4,a3,0x3
    80003020:	00005797          	auipc	a5,0x5
    80003024:	43878793          	addi	a5,a5,1080 # 80008458 <syscalls>
    80003028:	97ba                	add	a5,a5,a4
    8000302a:	6398                	ld	a4,0(a5)
    8000302c:	ff4d                	bnez	a4,80002fe6 <syscall+0x48>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000302e:	16048613          	addi	a2,s1,352
    80003032:	588c                	lw	a1,48(s1)
    80003034:	00005517          	auipc	a0,0x5
    80003038:	3ec50513          	addi	a0,a0,1004 # 80008420 <states.0+0x150>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	54c080e7          	jalr	1356(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003044:	70bc                	ld	a5,96(s1)
    80003046:	577d                	li	a4,-1
    80003048:	fbb8                	sd	a4,112(a5)
  }
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6902                	ld	s2,0(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000305e:	fec40593          	addi	a1,s0,-20
    80003062:	4501                	li	a0,0
    80003064:	00000097          	auipc	ra,0x0
    80003068:	ec2080e7          	jalr	-318(ra) # 80002f26 <argint>
  exit(n);
    8000306c:	fec42503          	lw	a0,-20(s0)
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	356080e7          	jalr	854(ra) # 800023c6 <exit>
  return 0; // not reached
}
    80003078:	4501                	li	a0,0
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	6105                	addi	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003082:	1141                	addi	sp,sp,-16
    80003084:	e406                	sd	ra,8(sp)
    80003086:	e022                	sd	s0,0(sp)
    80003088:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	a08080e7          	jalr	-1528(ra) # 80001a92 <myproc>
}
    80003092:	5908                	lw	a0,48(a0)
    80003094:	60a2                	ld	ra,8(sp)
    80003096:	6402                	ld	s0,0(sp)
    80003098:	0141                	addi	sp,sp,16
    8000309a:	8082                	ret

000000008000309c <sys_fork>:

uint64
sys_fork(void)
{
    8000309c:	1141                	addi	sp,sp,-16
    8000309e:	e406                	sd	ra,8(sp)
    800030a0:	e022                	sd	s0,0(sp)
    800030a2:	0800                	addi	s0,sp,16
  return fork();
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	df2080e7          	jalr	-526(ra) # 80001e96 <fork>
}
    800030ac:	60a2                	ld	ra,8(sp)
    800030ae:	6402                	ld	s0,0(sp)
    800030b0:	0141                	addi	sp,sp,16
    800030b2:	8082                	ret

00000000800030b4 <sys_wait>:

uint64
sys_wait(void)
{
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030bc:	fe840593          	addi	a1,s0,-24
    800030c0:	4501                	li	a0,0
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	e84080e7          	jalr	-380(ra) # 80002f46 <argaddr>
  return wait(p);
    800030ca:	fe843503          	ld	a0,-24(s0)
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	4aa080e7          	jalr	1194(ra) # 80002578 <wait>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	6105                	addi	sp,sp,32
    800030dc:	8082                	ret

00000000800030de <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030de:	7179                	addi	sp,sp,-48
    800030e0:	f406                	sd	ra,40(sp)
    800030e2:	f022                	sd	s0,32(sp)
    800030e4:	ec26                	sd	s1,24(sp)
    800030e6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030e8:	fdc40593          	addi	a1,s0,-36
    800030ec:	4501                	li	a0,0
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	e38080e7          	jalr	-456(ra) # 80002f26 <argint>
  addr = myproc()->sz;
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	99c080e7          	jalr	-1636(ra) # 80001a92 <myproc>
    800030fe:	6924                	ld	s1,80(a0)
  if (growproc(n) < 0)
    80003100:	fdc42503          	lw	a0,-36(s0)
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	d36080e7          	jalr	-714(ra) # 80001e3a <growproc>
    8000310c:	00054863          	bltz	a0,8000311c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003110:	8526                	mv	a0,s1
    80003112:	70a2                	ld	ra,40(sp)
    80003114:	7402                	ld	s0,32(sp)
    80003116:	64e2                	ld	s1,24(sp)
    80003118:	6145                	addi	sp,sp,48
    8000311a:	8082                	ret
    return -1;
    8000311c:	54fd                	li	s1,-1
    8000311e:	bfcd                	j	80003110 <sys_sbrk+0x32>

0000000080003120 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003120:	7139                	addi	sp,sp,-64
    80003122:	fc06                	sd	ra,56(sp)
    80003124:	f822                	sd	s0,48(sp)
    80003126:	f426                	sd	s1,40(sp)
    80003128:	f04a                	sd	s2,32(sp)
    8000312a:	ec4e                	sd	s3,24(sp)
    8000312c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000312e:	fcc40593          	addi	a1,s0,-52
    80003132:	4501                	li	a0,0
    80003134:	00000097          	auipc	ra,0x0
    80003138:	df2080e7          	jalr	-526(ra) # 80002f26 <argint>
  acquire(&tickslock);
    8000313c:	00016517          	auipc	a0,0x16
    80003140:	27450513          	addi	a0,a0,628 # 800193b0 <tickslock>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	a92080e7          	jalr	-1390(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000314c:	00005917          	auipc	s2,0x5
    80003150:	7a492903          	lw	s2,1956(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80003154:	fcc42783          	lw	a5,-52(s0)
    80003158:	cf9d                	beqz	a5,80003196 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000315a:	00016997          	auipc	s3,0x16
    8000315e:	25698993          	addi	s3,s3,598 # 800193b0 <tickslock>
    80003162:	00005497          	auipc	s1,0x5
    80003166:	78e48493          	addi	s1,s1,1934 # 800088f0 <ticks>
    if (killed(myproc()))
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	928080e7          	jalr	-1752(ra) # 80001a92 <myproc>
    80003172:	fffff097          	auipc	ra,0xfffff
    80003176:	3d4080e7          	jalr	980(ra) # 80002546 <killed>
    8000317a:	ed15                	bnez	a0,800031b6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000317c:	85ce                	mv	a1,s3
    8000317e:	8526                	mv	a0,s1
    80003180:	fffff097          	auipc	ra,0xfffff
    80003184:	112080e7          	jalr	274(ra) # 80002292 <sleep>
  while (ticks - ticks0 < n)
    80003188:	409c                	lw	a5,0(s1)
    8000318a:	412787bb          	subw	a5,a5,s2
    8000318e:	fcc42703          	lw	a4,-52(s0)
    80003192:	fce7ece3          	bltu	a5,a4,8000316a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003196:	00016517          	auipc	a0,0x16
    8000319a:	21a50513          	addi	a0,a0,538 # 800193b0 <tickslock>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
  return 0;
    800031a6:	4501                	li	a0,0
}
    800031a8:	70e2                	ld	ra,56(sp)
    800031aa:	7442                	ld	s0,48(sp)
    800031ac:	74a2                	ld	s1,40(sp)
    800031ae:	7902                	ld	s2,32(sp)
    800031b0:	69e2                	ld	s3,24(sp)
    800031b2:	6121                	addi	sp,sp,64
    800031b4:	8082                	ret
      release(&tickslock);
    800031b6:	00016517          	auipc	a0,0x16
    800031ba:	1fa50513          	addi	a0,a0,506 # 800193b0 <tickslock>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
      return -1;
    800031c6:	557d                	li	a0,-1
    800031c8:	b7c5                	j	800031a8 <sys_sleep+0x88>

00000000800031ca <sys_kill>:

uint64
sys_kill(void)
{
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800031d2:	fec40593          	addi	a1,s0,-20
    800031d6:	4501                	li	a0,0
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	d4e080e7          	jalr	-690(ra) # 80002f26 <argint>
  return kill(pid);
    800031e0:	fec42503          	lw	a0,-20(s0)
    800031e4:	fffff097          	auipc	ra,0xfffff
    800031e8:	2c4080e7          	jalr	708(ra) # 800024a8 <kill>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret

00000000800031f4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031fe:	00016517          	auipc	a0,0x16
    80003202:	1b250513          	addi	a0,a0,434 # 800193b0 <tickslock>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	9d0080e7          	jalr	-1584(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000320e:	00005497          	auipc	s1,0x5
    80003212:	6e24a483          	lw	s1,1762(s1) # 800088f0 <ticks>
  release(&tickslock);
    80003216:	00016517          	auipc	a0,0x16
    8000321a:	19a50513          	addi	a0,a0,410 # 800193b0 <tickslock>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>
  return xticks;
}
    80003226:	02049513          	slli	a0,s1,0x20
    8000322a:	9101                	srli	a0,a0,0x20
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret

0000000080003236 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003236:	7139                	addi	sp,sp,-64
    80003238:	fc06                	sd	ra,56(sp)
    8000323a:	f822                	sd	s0,48(sp)
    8000323c:	f426                	sd	s1,40(sp)
    8000323e:	f04a                	sd	s2,32(sp)
    80003240:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003242:	fd840593          	addi	a1,s0,-40
    80003246:	4501                	li	a0,0
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	cfe080e7          	jalr	-770(ra) # 80002f46 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003250:	fd040593          	addi	a1,s0,-48
    80003254:	4505                	li	a0,1
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	cf0080e7          	jalr	-784(ra) # 80002f46 <argaddr>
  argaddr(2, &addr2);
    8000325e:	fc840593          	addi	a1,s0,-56
    80003262:	4509                	li	a0,2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	ce2080e7          	jalr	-798(ra) # 80002f46 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000326c:	fc040613          	addi	a2,s0,-64
    80003270:	fc440593          	addi	a1,s0,-60
    80003274:	fd843503          	ld	a0,-40(s0)
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	588080e7          	jalr	1416(ra) # 80002800 <waitx>
    80003280:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003282:	fffff097          	auipc	ra,0xfffff
    80003286:	810080e7          	jalr	-2032(ra) # 80001a92 <myproc>
    8000328a:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000328c:	4691                	li	a3,4
    8000328e:	fc440613          	addi	a2,s0,-60
    80003292:	fd043583          	ld	a1,-48(s0)
    80003296:	6d28                	ld	a0,88(a0)
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	3d0080e7          	jalr	976(ra) # 80001668 <copyout>
    return -1;
    800032a0:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800032a2:	00054f63          	bltz	a0,800032c0 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800032a6:	4691                	li	a3,4
    800032a8:	fc040613          	addi	a2,s0,-64
    800032ac:	fc843583          	ld	a1,-56(s0)
    800032b0:	6ca8                	ld	a0,88(s1)
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	3b6080e7          	jalr	950(ra) # 80001668 <copyout>
    800032ba:	00054a63          	bltz	a0,800032ce <sys_waitx+0x98>
    return -1;
  return ret;
    800032be:	87ca                	mv	a5,s2
}
    800032c0:	853e                	mv	a0,a5
    800032c2:	70e2                	ld	ra,56(sp)
    800032c4:	7442                	ld	s0,48(sp)
    800032c6:	74a2                	ld	s1,40(sp)
    800032c8:	7902                	ld	s2,32(sp)
    800032ca:	6121                	addi	sp,sp,64
    800032cc:	8082                	ret
    return -1;
    800032ce:	57fd                	li	a5,-1
    800032d0:	bfc5                	j	800032c0 <sys_waitx+0x8a>

00000000800032d2 <sys_sigalarm>:


uint64 sys_sigalarm(void)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    800032da:	fe440593          	addi	a1,s0,-28
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	c46080e7          	jalr	-954(ra) # 80002f26 <argint>
  argaddr(1, &addr);
    800032e8:	fe840593          	addi	a1,s0,-24
    800032ec:	4505                	li	a0,1
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	c58080e7          	jalr	-936(ra) # 80002f46 <argaddr>

  myproc()->ticks = ticks;
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	79c080e7          	jalr	1948(ra) # 80001a92 <myproc>
    800032fe:	fe442783          	lw	a5,-28(s0)
    80003302:	1cf52623          	sw	a5,460(a0)
  myproc()->alarm_on=0;
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	78c080e7          	jalr	1932(ra) # 80001a92 <myproc>
    8000330e:	1e052023          	sw	zero,480(a0)
  myproc()->cur_ticks=0;
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	780080e7          	jalr	1920(ra) # 80001a92 <myproc>
    8000331a:	1c052823          	sw	zero,464(a0)
  myproc()->handler = addr;
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	774080e7          	jalr	1908(ra) # 80001a92 <myproc>
    80003326:	fe843783          	ld	a5,-24(s0)
    8000332a:	1ef53423          	sd	a5,488(a0)

  return 0;
}
    8000332e:	4501                	li	a0,0
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret

0000000080003338 <sys_sigreturn>:


uint64 sys_sigreturn(void)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	750080e7          	jalr	1872(ra) # 80001a92 <myproc>
    8000334a:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    8000334c:	6605                	lui	a2,0x1
    8000334e:	1d853583          	ld	a1,472(a0)
    80003352:	7128                	ld	a0,96(a0)
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	9da080e7          	jalr	-1574(ra) # 80000d2e <memmove>

  kfree(p->alarm_tf);
    8000335c:	1d84b503          	ld	a0,472(s1)
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	68a080e7          	jalr	1674(ra) # 800009ea <kfree>
  p->alarm_tf = 0;
    80003368:	1c04bc23          	sd	zero,472(s1)
  p->alarm_on = 0;
    8000336c:	1e04a023          	sw	zero,480(s1)
  p->cur_ticks = 0;
    80003370:	1c04a823          	sw	zero,464(s1)
  usertrapret();
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	6e0080e7          	jalr	1760(ra) # 80002a54 <usertrapret>
  return 0;
}
    8000337c:	4501                	li	a0,0
    8000337e:	60e2                	ld	ra,24(sp)
    80003380:	6442                	ld	s0,16(sp)
    80003382:	64a2                	ld	s1,8(sp)
    80003384:	6105                	addi	sp,sp,32
    80003386:	8082                	ret

0000000080003388 <sys_getreadcount>:
int
sys_getreadcount(void)
{
    80003388:	1141                	addi	sp,sp,-16
    8000338a:	e406                	sd	ra,8(sp)
    8000338c:	e022                	sd	s0,0(sp)
    8000338e:	0800                	addi	s0,sp,16
  return myproc()->readcallcount;
    80003390:	ffffe097          	auipc	ra,0xffffe
    80003394:	702080e7          	jalr	1794(ra) # 80001a92 <myproc>
}
    80003398:	4128                	lw	a0,64(a0)
    8000339a:	60a2                	ld	ra,8(sp)
    8000339c:	6402                	ld	s0,0(sp)
    8000339e:	0141                	addi	sp,sp,16
    800033a0:	8082                	ret

00000000800033a2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033a2:	7179                	addi	sp,sp,-48
    800033a4:	f406                	sd	ra,40(sp)
    800033a6:	f022                	sd	s0,32(sp)
    800033a8:	ec26                	sd	s1,24(sp)
    800033aa:	e84a                	sd	s2,16(sp)
    800033ac:	e44e                	sd	s3,8(sp)
    800033ae:	e052                	sd	s4,0(sp)
    800033b0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033b2:	00005597          	auipc	a1,0x5
    800033b6:	17658593          	addi	a1,a1,374 # 80008528 <syscalls+0xd0>
    800033ba:	00016517          	auipc	a0,0x16
    800033be:	00e50513          	addi	a0,a0,14 # 800193c8 <bcache>
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	784080e7          	jalr	1924(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033ca:	0001e797          	auipc	a5,0x1e
    800033ce:	ffe78793          	addi	a5,a5,-2 # 800213c8 <bcache+0x8000>
    800033d2:	0001e717          	auipc	a4,0x1e
    800033d6:	25e70713          	addi	a4,a4,606 # 80021630 <bcache+0x8268>
    800033da:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033de:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033e2:	00016497          	auipc	s1,0x16
    800033e6:	ffe48493          	addi	s1,s1,-2 # 800193e0 <bcache+0x18>
    b->next = bcache.head.next;
    800033ea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033ec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033ee:	00005a17          	auipc	s4,0x5
    800033f2:	142a0a13          	addi	s4,s4,322 # 80008530 <syscalls+0xd8>
    b->next = bcache.head.next;
    800033f6:	2b893783          	ld	a5,696(s2)
    800033fa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033fc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003400:	85d2                	mv	a1,s4
    80003402:	01048513          	addi	a0,s1,16
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	4c4080e7          	jalr	1220(ra) # 800048ca <initsleeplock>
    bcache.head.next->prev = b;
    8000340e:	2b893783          	ld	a5,696(s2)
    80003412:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003414:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003418:	45848493          	addi	s1,s1,1112
    8000341c:	fd349de3          	bne	s1,s3,800033f6 <binit+0x54>
  }
}
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6942                	ld	s2,16(sp)
    80003428:	69a2                	ld	s3,8(sp)
    8000342a:	6a02                	ld	s4,0(sp)
    8000342c:	6145                	addi	sp,sp,48
    8000342e:	8082                	ret

0000000080003430 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003430:	7179                	addi	sp,sp,-48
    80003432:	f406                	sd	ra,40(sp)
    80003434:	f022                	sd	s0,32(sp)
    80003436:	ec26                	sd	s1,24(sp)
    80003438:	e84a                	sd	s2,16(sp)
    8000343a:	e44e                	sd	s3,8(sp)
    8000343c:	1800                	addi	s0,sp,48
    8000343e:	892a                	mv	s2,a0
    80003440:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003442:	00016517          	auipc	a0,0x16
    80003446:	f8650513          	addi	a0,a0,-122 # 800193c8 <bcache>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	78c080e7          	jalr	1932(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003452:	0001e497          	auipc	s1,0x1e
    80003456:	22e4b483          	ld	s1,558(s1) # 80021680 <bcache+0x82b8>
    8000345a:	0001e797          	auipc	a5,0x1e
    8000345e:	1d678793          	addi	a5,a5,470 # 80021630 <bcache+0x8268>
    80003462:	02f48f63          	beq	s1,a5,800034a0 <bread+0x70>
    80003466:	873e                	mv	a4,a5
    80003468:	a021                	j	80003470 <bread+0x40>
    8000346a:	68a4                	ld	s1,80(s1)
    8000346c:	02e48a63          	beq	s1,a4,800034a0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003470:	449c                	lw	a5,8(s1)
    80003472:	ff279ce3          	bne	a5,s2,8000346a <bread+0x3a>
    80003476:	44dc                	lw	a5,12(s1)
    80003478:	ff3799e3          	bne	a5,s3,8000346a <bread+0x3a>
      b->refcnt++;
    8000347c:	40bc                	lw	a5,64(s1)
    8000347e:	2785                	addiw	a5,a5,1
    80003480:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003482:	00016517          	auipc	a0,0x16
    80003486:	f4650513          	addi	a0,a0,-186 # 800193c8 <bcache>
    8000348a:	ffffe097          	auipc	ra,0xffffe
    8000348e:	800080e7          	jalr	-2048(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003492:	01048513          	addi	a0,s1,16
    80003496:	00001097          	auipc	ra,0x1
    8000349a:	46e080e7          	jalr	1134(ra) # 80004904 <acquiresleep>
      return b;
    8000349e:	a8b9                	j	800034fc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034a0:	0001e497          	auipc	s1,0x1e
    800034a4:	1d84b483          	ld	s1,472(s1) # 80021678 <bcache+0x82b0>
    800034a8:	0001e797          	auipc	a5,0x1e
    800034ac:	18878793          	addi	a5,a5,392 # 80021630 <bcache+0x8268>
    800034b0:	00f48863          	beq	s1,a5,800034c0 <bread+0x90>
    800034b4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034b6:	40bc                	lw	a5,64(s1)
    800034b8:	cf81                	beqz	a5,800034d0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ba:	64a4                	ld	s1,72(s1)
    800034bc:	fee49de3          	bne	s1,a4,800034b6 <bread+0x86>
  panic("bget: no buffers");
    800034c0:	00005517          	auipc	a0,0x5
    800034c4:	07850513          	addi	a0,a0,120 # 80008538 <syscalls+0xe0>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	076080e7          	jalr	118(ra) # 8000053e <panic>
      b->dev = dev;
    800034d0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034d4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034d8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034dc:	4785                	li	a5,1
    800034de:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034e0:	00016517          	auipc	a0,0x16
    800034e4:	ee850513          	addi	a0,a0,-280 # 800193c8 <bcache>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	7a2080e7          	jalr	1954(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034f0:	01048513          	addi	a0,s1,16
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	410080e7          	jalr	1040(ra) # 80004904 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034fc:	409c                	lw	a5,0(s1)
    800034fe:	cb89                	beqz	a5,80003510 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003500:	8526                	mv	a0,s1
    80003502:	70a2                	ld	ra,40(sp)
    80003504:	7402                	ld	s0,32(sp)
    80003506:	64e2                	ld	s1,24(sp)
    80003508:	6942                	ld	s2,16(sp)
    8000350a:	69a2                	ld	s3,8(sp)
    8000350c:	6145                	addi	sp,sp,48
    8000350e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003510:	4581                	li	a1,0
    80003512:	8526                	mv	a0,s1
    80003514:	00003097          	auipc	ra,0x3
    80003518:	fd0080e7          	jalr	-48(ra) # 800064e4 <virtio_disk_rw>
    b->valid = 1;
    8000351c:	4785                	li	a5,1
    8000351e:	c09c                	sw	a5,0(s1)
  return b;
    80003520:	b7c5                	j	80003500 <bread+0xd0>

0000000080003522 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003522:	1101                	addi	sp,sp,-32
    80003524:	ec06                	sd	ra,24(sp)
    80003526:	e822                	sd	s0,16(sp)
    80003528:	e426                	sd	s1,8(sp)
    8000352a:	1000                	addi	s0,sp,32
    8000352c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000352e:	0541                	addi	a0,a0,16
    80003530:	00001097          	auipc	ra,0x1
    80003534:	46e080e7          	jalr	1134(ra) # 8000499e <holdingsleep>
    80003538:	cd01                	beqz	a0,80003550 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000353a:	4585                	li	a1,1
    8000353c:	8526                	mv	a0,s1
    8000353e:	00003097          	auipc	ra,0x3
    80003542:	fa6080e7          	jalr	-90(ra) # 800064e4 <virtio_disk_rw>
}
    80003546:	60e2                	ld	ra,24(sp)
    80003548:	6442                	ld	s0,16(sp)
    8000354a:	64a2                	ld	s1,8(sp)
    8000354c:	6105                	addi	sp,sp,32
    8000354e:	8082                	ret
    panic("bwrite");
    80003550:	00005517          	auipc	a0,0x5
    80003554:	00050513          	mv	a0,a0
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>

0000000080003560 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003560:	1101                	addi	sp,sp,-32
    80003562:	ec06                	sd	ra,24(sp)
    80003564:	e822                	sd	s0,16(sp)
    80003566:	e426                	sd	s1,8(sp)
    80003568:	e04a                	sd	s2,0(sp)
    8000356a:	1000                	addi	s0,sp,32
    8000356c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000356e:	01050913          	addi	s2,a0,16 # 80008560 <syscalls+0x108>
    80003572:	854a                	mv	a0,s2
    80003574:	00001097          	auipc	ra,0x1
    80003578:	42a080e7          	jalr	1066(ra) # 8000499e <holdingsleep>
    8000357c:	c92d                	beqz	a0,800035ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000357e:	854a                	mv	a0,s2
    80003580:	00001097          	auipc	ra,0x1
    80003584:	3da080e7          	jalr	986(ra) # 8000495a <releasesleep>

  acquire(&bcache.lock);
    80003588:	00016517          	auipc	a0,0x16
    8000358c:	e4050513          	addi	a0,a0,-448 # 800193c8 <bcache>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	646080e7          	jalr	1606(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003598:	40bc                	lw	a5,64(s1)
    8000359a:	37fd                	addiw	a5,a5,-1
    8000359c:	0007871b          	sext.w	a4,a5
    800035a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035a2:	eb05                	bnez	a4,800035d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035a4:	68bc                	ld	a5,80(s1)
    800035a6:	64b8                	ld	a4,72(s1)
    800035a8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035aa:	64bc                	ld	a5,72(s1)
    800035ac:	68b8                	ld	a4,80(s1)
    800035ae:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035b0:	0001e797          	auipc	a5,0x1e
    800035b4:	e1878793          	addi	a5,a5,-488 # 800213c8 <bcache+0x8000>
    800035b8:	2b87b703          	ld	a4,696(a5)
    800035bc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035be:	0001e717          	auipc	a4,0x1e
    800035c2:	07270713          	addi	a4,a4,114 # 80021630 <bcache+0x8268>
    800035c6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035c8:	2b87b703          	ld	a4,696(a5)
    800035cc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035ce:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035d2:	00016517          	auipc	a0,0x16
    800035d6:	df650513          	addi	a0,a0,-522 # 800193c8 <bcache>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	6b0080e7          	jalr	1712(ra) # 80000c8a <release>
}
    800035e2:	60e2                	ld	ra,24(sp)
    800035e4:	6442                	ld	s0,16(sp)
    800035e6:	64a2                	ld	s1,8(sp)
    800035e8:	6902                	ld	s2,0(sp)
    800035ea:	6105                	addi	sp,sp,32
    800035ec:	8082                	ret
    panic("brelse");
    800035ee:	00005517          	auipc	a0,0x5
    800035f2:	f6a50513          	addi	a0,a0,-150 # 80008558 <syscalls+0x100>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>

00000000800035fe <bpin>:

void
bpin(struct buf *b) {
    800035fe:	1101                	addi	sp,sp,-32
    80003600:	ec06                	sd	ra,24(sp)
    80003602:	e822                	sd	s0,16(sp)
    80003604:	e426                	sd	s1,8(sp)
    80003606:	1000                	addi	s0,sp,32
    80003608:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000360a:	00016517          	auipc	a0,0x16
    8000360e:	dbe50513          	addi	a0,a0,-578 # 800193c8 <bcache>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	5c4080e7          	jalr	1476(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000361a:	40bc                	lw	a5,64(s1)
    8000361c:	2785                	addiw	a5,a5,1
    8000361e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003620:	00016517          	auipc	a0,0x16
    80003624:	da850513          	addi	a0,a0,-600 # 800193c8 <bcache>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	662080e7          	jalr	1634(ra) # 80000c8a <release>
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6105                	addi	sp,sp,32
    80003638:	8082                	ret

000000008000363a <bunpin>:

void
bunpin(struct buf *b) {
    8000363a:	1101                	addi	sp,sp,-32
    8000363c:	ec06                	sd	ra,24(sp)
    8000363e:	e822                	sd	s0,16(sp)
    80003640:	e426                	sd	s1,8(sp)
    80003642:	1000                	addi	s0,sp,32
    80003644:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003646:	00016517          	auipc	a0,0x16
    8000364a:	d8250513          	addi	a0,a0,-638 # 800193c8 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	588080e7          	jalr	1416(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003656:	40bc                	lw	a5,64(s1)
    80003658:	37fd                	addiw	a5,a5,-1
    8000365a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000365c:	00016517          	auipc	a0,0x16
    80003660:	d6c50513          	addi	a0,a0,-660 # 800193c8 <bcache>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
}
    8000366c:	60e2                	ld	ra,24(sp)
    8000366e:	6442                	ld	s0,16(sp)
    80003670:	64a2                	ld	s1,8(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret

0000000080003676 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003676:	1101                	addi	sp,sp,-32
    80003678:	ec06                	sd	ra,24(sp)
    8000367a:	e822                	sd	s0,16(sp)
    8000367c:	e426                	sd	s1,8(sp)
    8000367e:	e04a                	sd	s2,0(sp)
    80003680:	1000                	addi	s0,sp,32
    80003682:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003684:	00d5d59b          	srliw	a1,a1,0xd
    80003688:	0001e797          	auipc	a5,0x1e
    8000368c:	41c7a783          	lw	a5,1052(a5) # 80021aa4 <sb+0x1c>
    80003690:	9dbd                	addw	a1,a1,a5
    80003692:	00000097          	auipc	ra,0x0
    80003696:	d9e080e7          	jalr	-610(ra) # 80003430 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000369a:	0074f713          	andi	a4,s1,7
    8000369e:	4785                	li	a5,1
    800036a0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036a4:	14ce                	slli	s1,s1,0x33
    800036a6:	90d9                	srli	s1,s1,0x36
    800036a8:	00950733          	add	a4,a0,s1
    800036ac:	05874703          	lbu	a4,88(a4)
    800036b0:	00e7f6b3          	and	a3,a5,a4
    800036b4:	c69d                	beqz	a3,800036e2 <bfree+0x6c>
    800036b6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036b8:	94aa                	add	s1,s1,a0
    800036ba:	fff7c793          	not	a5,a5
    800036be:	8ff9                	and	a5,a5,a4
    800036c0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	120080e7          	jalr	288(ra) # 800047e4 <log_write>
  brelse(bp);
    800036cc:	854a                	mv	a0,s2
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	e92080e7          	jalr	-366(ra) # 80003560 <brelse>
}
    800036d6:	60e2                	ld	ra,24(sp)
    800036d8:	6442                	ld	s0,16(sp)
    800036da:	64a2                	ld	s1,8(sp)
    800036dc:	6902                	ld	s2,0(sp)
    800036de:	6105                	addi	sp,sp,32
    800036e0:	8082                	ret
    panic("freeing free block");
    800036e2:	00005517          	auipc	a0,0x5
    800036e6:	e7e50513          	addi	a0,a0,-386 # 80008560 <syscalls+0x108>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>

00000000800036f2 <balloc>:
{
    800036f2:	711d                	addi	sp,sp,-96
    800036f4:	ec86                	sd	ra,88(sp)
    800036f6:	e8a2                	sd	s0,80(sp)
    800036f8:	e4a6                	sd	s1,72(sp)
    800036fa:	e0ca                	sd	s2,64(sp)
    800036fc:	fc4e                	sd	s3,56(sp)
    800036fe:	f852                	sd	s4,48(sp)
    80003700:	f456                	sd	s5,40(sp)
    80003702:	f05a                	sd	s6,32(sp)
    80003704:	ec5e                	sd	s7,24(sp)
    80003706:	e862                	sd	s8,16(sp)
    80003708:	e466                	sd	s9,8(sp)
    8000370a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000370c:	0001e797          	auipc	a5,0x1e
    80003710:	3807a783          	lw	a5,896(a5) # 80021a8c <sb+0x4>
    80003714:	10078163          	beqz	a5,80003816 <balloc+0x124>
    80003718:	8baa                	mv	s7,a0
    8000371a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000371c:	0001eb17          	auipc	s6,0x1e
    80003720:	36cb0b13          	addi	s6,s6,876 # 80021a88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003724:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003726:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003728:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000372a:	6c89                	lui	s9,0x2
    8000372c:	a061                	j	800037b4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000372e:	974a                	add	a4,a4,s2
    80003730:	8fd5                	or	a5,a5,a3
    80003732:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	0ac080e7          	jalr	172(ra) # 800047e4 <log_write>
        brelse(bp);
    80003740:	854a                	mv	a0,s2
    80003742:	00000097          	auipc	ra,0x0
    80003746:	e1e080e7          	jalr	-482(ra) # 80003560 <brelse>
  bp = bread(dev, bno);
    8000374a:	85a6                	mv	a1,s1
    8000374c:	855e                	mv	a0,s7
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	ce2080e7          	jalr	-798(ra) # 80003430 <bread>
    80003756:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003758:	40000613          	li	a2,1024
    8000375c:	4581                	li	a1,0
    8000375e:	05850513          	addi	a0,a0,88
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	570080e7          	jalr	1392(ra) # 80000cd2 <memset>
  log_write(bp);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	078080e7          	jalr	120(ra) # 800047e4 <log_write>
  brelse(bp);
    80003774:	854a                	mv	a0,s2
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	dea080e7          	jalr	-534(ra) # 80003560 <brelse>
}
    8000377e:	8526                	mv	a0,s1
    80003780:	60e6                	ld	ra,88(sp)
    80003782:	6446                	ld	s0,80(sp)
    80003784:	64a6                	ld	s1,72(sp)
    80003786:	6906                	ld	s2,64(sp)
    80003788:	79e2                	ld	s3,56(sp)
    8000378a:	7a42                	ld	s4,48(sp)
    8000378c:	7aa2                	ld	s5,40(sp)
    8000378e:	7b02                	ld	s6,32(sp)
    80003790:	6be2                	ld	s7,24(sp)
    80003792:	6c42                	ld	s8,16(sp)
    80003794:	6ca2                	ld	s9,8(sp)
    80003796:	6125                	addi	sp,sp,96
    80003798:	8082                	ret
    brelse(bp);
    8000379a:	854a                	mv	a0,s2
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	dc4080e7          	jalr	-572(ra) # 80003560 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037a4:	015c87bb          	addw	a5,s9,s5
    800037a8:	00078a9b          	sext.w	s5,a5
    800037ac:	004b2703          	lw	a4,4(s6)
    800037b0:	06eaf363          	bgeu	s5,a4,80003816 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800037b4:	41fad79b          	sraiw	a5,s5,0x1f
    800037b8:	0137d79b          	srliw	a5,a5,0x13
    800037bc:	015787bb          	addw	a5,a5,s5
    800037c0:	40d7d79b          	sraiw	a5,a5,0xd
    800037c4:	01cb2583          	lw	a1,28(s6)
    800037c8:	9dbd                	addw	a1,a1,a5
    800037ca:	855e                	mv	a0,s7
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	c64080e7          	jalr	-924(ra) # 80003430 <bread>
    800037d4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037d6:	004b2503          	lw	a0,4(s6)
    800037da:	000a849b          	sext.w	s1,s5
    800037de:	8662                	mv	a2,s8
    800037e0:	faa4fde3          	bgeu	s1,a0,8000379a <balloc+0xa8>
      m = 1 << (bi % 8);
    800037e4:	41f6579b          	sraiw	a5,a2,0x1f
    800037e8:	01d7d69b          	srliw	a3,a5,0x1d
    800037ec:	00c6873b          	addw	a4,a3,a2
    800037f0:	00777793          	andi	a5,a4,7
    800037f4:	9f95                	subw	a5,a5,a3
    800037f6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037fa:	4037571b          	sraiw	a4,a4,0x3
    800037fe:	00e906b3          	add	a3,s2,a4
    80003802:	0586c683          	lbu	a3,88(a3)
    80003806:	00d7f5b3          	and	a1,a5,a3
    8000380a:	d195                	beqz	a1,8000372e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000380c:	2605                	addiw	a2,a2,1
    8000380e:	2485                	addiw	s1,s1,1
    80003810:	fd4618e3          	bne	a2,s4,800037e0 <balloc+0xee>
    80003814:	b759                	j	8000379a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003816:	00005517          	auipc	a0,0x5
    8000381a:	d6250513          	addi	a0,a0,-670 # 80008578 <syscalls+0x120>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	d6a080e7          	jalr	-662(ra) # 80000588 <printf>
  return 0;
    80003826:	4481                	li	s1,0
    80003828:	bf99                	j	8000377e <balloc+0x8c>

000000008000382a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000382a:	7179                	addi	sp,sp,-48
    8000382c:	f406                	sd	ra,40(sp)
    8000382e:	f022                	sd	s0,32(sp)
    80003830:	ec26                	sd	s1,24(sp)
    80003832:	e84a                	sd	s2,16(sp)
    80003834:	e44e                	sd	s3,8(sp)
    80003836:	e052                	sd	s4,0(sp)
    80003838:	1800                	addi	s0,sp,48
    8000383a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000383c:	47ad                	li	a5,11
    8000383e:	02b7e763          	bltu	a5,a1,8000386c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003842:	02059493          	slli	s1,a1,0x20
    80003846:	9081                	srli	s1,s1,0x20
    80003848:	048a                	slli	s1,s1,0x2
    8000384a:	94aa                	add	s1,s1,a0
    8000384c:	0504a903          	lw	s2,80(s1)
    80003850:	06091e63          	bnez	s2,800038cc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003854:	4108                	lw	a0,0(a0)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	e9c080e7          	jalr	-356(ra) # 800036f2 <balloc>
    8000385e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003862:	06090563          	beqz	s2,800038cc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003866:	0524a823          	sw	s2,80(s1)
    8000386a:	a08d                	j	800038cc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000386c:	ff45849b          	addiw	s1,a1,-12
    80003870:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003874:	0ff00793          	li	a5,255
    80003878:	08e7e563          	bltu	a5,a4,80003902 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000387c:	08052903          	lw	s2,128(a0)
    80003880:	00091d63          	bnez	s2,8000389a <bmap+0x70>
      addr = balloc(ip->dev);
    80003884:	4108                	lw	a0,0(a0)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	e6c080e7          	jalr	-404(ra) # 800036f2 <balloc>
    8000388e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003892:	02090d63          	beqz	s2,800038cc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003896:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000389a:	85ca                	mv	a1,s2
    8000389c:	0009a503          	lw	a0,0(s3)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	b90080e7          	jalr	-1136(ra) # 80003430 <bread>
    800038a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038ae:	02049593          	slli	a1,s1,0x20
    800038b2:	9181                	srli	a1,a1,0x20
    800038b4:	058a                	slli	a1,a1,0x2
    800038b6:	00b784b3          	add	s1,a5,a1
    800038ba:	0004a903          	lw	s2,0(s1)
    800038be:	02090063          	beqz	s2,800038de <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038c2:	8552                	mv	a0,s4
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	c9c080e7          	jalr	-868(ra) # 80003560 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038cc:	854a                	mv	a0,s2
    800038ce:	70a2                	ld	ra,40(sp)
    800038d0:	7402                	ld	s0,32(sp)
    800038d2:	64e2                	ld	s1,24(sp)
    800038d4:	6942                	ld	s2,16(sp)
    800038d6:	69a2                	ld	s3,8(sp)
    800038d8:	6a02                	ld	s4,0(sp)
    800038da:	6145                	addi	sp,sp,48
    800038dc:	8082                	ret
      addr = balloc(ip->dev);
    800038de:	0009a503          	lw	a0,0(s3)
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	e10080e7          	jalr	-496(ra) # 800036f2 <balloc>
    800038ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800038ee:	fc090ae3          	beqz	s2,800038c2 <bmap+0x98>
        a[bn] = addr;
    800038f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038f6:	8552                	mv	a0,s4
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	eec080e7          	jalr	-276(ra) # 800047e4 <log_write>
    80003900:	b7c9                	j	800038c2 <bmap+0x98>
  panic("bmap: out of range");
    80003902:	00005517          	auipc	a0,0x5
    80003906:	c8e50513          	addi	a0,a0,-882 # 80008590 <syscalls+0x138>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>

0000000080003912 <iget>:
{
    80003912:	7179                	addi	sp,sp,-48
    80003914:	f406                	sd	ra,40(sp)
    80003916:	f022                	sd	s0,32(sp)
    80003918:	ec26                	sd	s1,24(sp)
    8000391a:	e84a                	sd	s2,16(sp)
    8000391c:	e44e                	sd	s3,8(sp)
    8000391e:	e052                	sd	s4,0(sp)
    80003920:	1800                	addi	s0,sp,48
    80003922:	89aa                	mv	s3,a0
    80003924:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003926:	0001e517          	auipc	a0,0x1e
    8000392a:	18250513          	addi	a0,a0,386 # 80021aa8 <itable>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	2a8080e7          	jalr	680(ra) # 80000bd6 <acquire>
  empty = 0;
    80003936:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003938:	0001e497          	auipc	s1,0x1e
    8000393c:	18848493          	addi	s1,s1,392 # 80021ac0 <itable+0x18>
    80003940:	00020697          	auipc	a3,0x20
    80003944:	c1068693          	addi	a3,a3,-1008 # 80023550 <log>
    80003948:	a039                	j	80003956 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000394a:	02090b63          	beqz	s2,80003980 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000394e:	08848493          	addi	s1,s1,136
    80003952:	02d48a63          	beq	s1,a3,80003986 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003956:	449c                	lw	a5,8(s1)
    80003958:	fef059e3          	blez	a5,8000394a <iget+0x38>
    8000395c:	4098                	lw	a4,0(s1)
    8000395e:	ff3716e3          	bne	a4,s3,8000394a <iget+0x38>
    80003962:	40d8                	lw	a4,4(s1)
    80003964:	ff4713e3          	bne	a4,s4,8000394a <iget+0x38>
      ip->ref++;
    80003968:	2785                	addiw	a5,a5,1
    8000396a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000396c:	0001e517          	auipc	a0,0x1e
    80003970:	13c50513          	addi	a0,a0,316 # 80021aa8 <itable>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	316080e7          	jalr	790(ra) # 80000c8a <release>
      return ip;
    8000397c:	8926                	mv	s2,s1
    8000397e:	a03d                	j	800039ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003980:	f7f9                	bnez	a5,8000394e <iget+0x3c>
    80003982:	8926                	mv	s2,s1
    80003984:	b7e9                	j	8000394e <iget+0x3c>
  if(empty == 0)
    80003986:	02090c63          	beqz	s2,800039be <iget+0xac>
  ip->dev = dev;
    8000398a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000398e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003992:	4785                	li	a5,1
    80003994:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003998:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000399c:	0001e517          	auipc	a0,0x1e
    800039a0:	10c50513          	addi	a0,a0,268 # 80021aa8 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2e6080e7          	jalr	742(ra) # 80000c8a <release>
}
    800039ac:	854a                	mv	a0,s2
    800039ae:	70a2                	ld	ra,40(sp)
    800039b0:	7402                	ld	s0,32(sp)
    800039b2:	64e2                	ld	s1,24(sp)
    800039b4:	6942                	ld	s2,16(sp)
    800039b6:	69a2                	ld	s3,8(sp)
    800039b8:	6a02                	ld	s4,0(sp)
    800039ba:	6145                	addi	sp,sp,48
    800039bc:	8082                	ret
    panic("iget: no inodes");
    800039be:	00005517          	auipc	a0,0x5
    800039c2:	bea50513          	addi	a0,a0,-1046 # 800085a8 <syscalls+0x150>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	b78080e7          	jalr	-1160(ra) # 8000053e <panic>

00000000800039ce <fsinit>:
fsinit(int dev) {
    800039ce:	7179                	addi	sp,sp,-48
    800039d0:	f406                	sd	ra,40(sp)
    800039d2:	f022                	sd	s0,32(sp)
    800039d4:	ec26                	sd	s1,24(sp)
    800039d6:	e84a                	sd	s2,16(sp)
    800039d8:	e44e                	sd	s3,8(sp)
    800039da:	1800                	addi	s0,sp,48
    800039dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039de:	4585                	li	a1,1
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	a50080e7          	jalr	-1456(ra) # 80003430 <bread>
    800039e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039ea:	0001e997          	auipc	s3,0x1e
    800039ee:	09e98993          	addi	s3,s3,158 # 80021a88 <sb>
    800039f2:	02000613          	li	a2,32
    800039f6:	05850593          	addi	a1,a0,88
    800039fa:	854e                	mv	a0,s3
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	332080e7          	jalr	818(ra) # 80000d2e <memmove>
  brelse(bp);
    80003a04:	8526                	mv	a0,s1
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	b5a080e7          	jalr	-1190(ra) # 80003560 <brelse>
  if(sb.magic != FSMAGIC)
    80003a0e:	0009a703          	lw	a4,0(s3)
    80003a12:	102037b7          	lui	a5,0x10203
    80003a16:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a1a:	02f71263          	bne	a4,a5,80003a3e <fsinit+0x70>
  initlog(dev, &sb);
    80003a1e:	0001e597          	auipc	a1,0x1e
    80003a22:	06a58593          	addi	a1,a1,106 # 80021a88 <sb>
    80003a26:	854a                	mv	a0,s2
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	b40080e7          	jalr	-1216(ra) # 80004568 <initlog>
}
    80003a30:	70a2                	ld	ra,40(sp)
    80003a32:	7402                	ld	s0,32(sp)
    80003a34:	64e2                	ld	s1,24(sp)
    80003a36:	6942                	ld	s2,16(sp)
    80003a38:	69a2                	ld	s3,8(sp)
    80003a3a:	6145                	addi	sp,sp,48
    80003a3c:	8082                	ret
    panic("invalid file system");
    80003a3e:	00005517          	auipc	a0,0x5
    80003a42:	b7a50513          	addi	a0,a0,-1158 # 800085b8 <syscalls+0x160>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>

0000000080003a4e <iinit>:
{
    80003a4e:	7179                	addi	sp,sp,-48
    80003a50:	f406                	sd	ra,40(sp)
    80003a52:	f022                	sd	s0,32(sp)
    80003a54:	ec26                	sd	s1,24(sp)
    80003a56:	e84a                	sd	s2,16(sp)
    80003a58:	e44e                	sd	s3,8(sp)
    80003a5a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a5c:	00005597          	auipc	a1,0x5
    80003a60:	b7458593          	addi	a1,a1,-1164 # 800085d0 <syscalls+0x178>
    80003a64:	0001e517          	auipc	a0,0x1e
    80003a68:	04450513          	addi	a0,a0,68 # 80021aa8 <itable>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	0da080e7          	jalr	218(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a74:	0001e497          	auipc	s1,0x1e
    80003a78:	05c48493          	addi	s1,s1,92 # 80021ad0 <itable+0x28>
    80003a7c:	00020997          	auipc	s3,0x20
    80003a80:	ae498993          	addi	s3,s3,-1308 # 80023560 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a84:	00005917          	auipc	s2,0x5
    80003a88:	b5490913          	addi	s2,s2,-1196 # 800085d8 <syscalls+0x180>
    80003a8c:	85ca                	mv	a1,s2
    80003a8e:	8526                	mv	a0,s1
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	e3a080e7          	jalr	-454(ra) # 800048ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a98:	08848493          	addi	s1,s1,136
    80003a9c:	ff3498e3          	bne	s1,s3,80003a8c <iinit+0x3e>
}
    80003aa0:	70a2                	ld	ra,40(sp)
    80003aa2:	7402                	ld	s0,32(sp)
    80003aa4:	64e2                	ld	s1,24(sp)
    80003aa6:	6942                	ld	s2,16(sp)
    80003aa8:	69a2                	ld	s3,8(sp)
    80003aaa:	6145                	addi	sp,sp,48
    80003aac:	8082                	ret

0000000080003aae <ialloc>:
{
    80003aae:	715d                	addi	sp,sp,-80
    80003ab0:	e486                	sd	ra,72(sp)
    80003ab2:	e0a2                	sd	s0,64(sp)
    80003ab4:	fc26                	sd	s1,56(sp)
    80003ab6:	f84a                	sd	s2,48(sp)
    80003ab8:	f44e                	sd	s3,40(sp)
    80003aba:	f052                	sd	s4,32(sp)
    80003abc:	ec56                	sd	s5,24(sp)
    80003abe:	e85a                	sd	s6,16(sp)
    80003ac0:	e45e                	sd	s7,8(sp)
    80003ac2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ac4:	0001e717          	auipc	a4,0x1e
    80003ac8:	fd072703          	lw	a4,-48(a4) # 80021a94 <sb+0xc>
    80003acc:	4785                	li	a5,1
    80003ace:	04e7fa63          	bgeu	a5,a4,80003b22 <ialloc+0x74>
    80003ad2:	8aaa                	mv	s5,a0
    80003ad4:	8bae                	mv	s7,a1
    80003ad6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ad8:	0001ea17          	auipc	s4,0x1e
    80003adc:	fb0a0a13          	addi	s4,s4,-80 # 80021a88 <sb>
    80003ae0:	00048b1b          	sext.w	s6,s1
    80003ae4:	0044d793          	srli	a5,s1,0x4
    80003ae8:	018a2583          	lw	a1,24(s4)
    80003aec:	9dbd                	addw	a1,a1,a5
    80003aee:	8556                	mv	a0,s5
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	940080e7          	jalr	-1728(ra) # 80003430 <bread>
    80003af8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003afa:	05850993          	addi	s3,a0,88
    80003afe:	00f4f793          	andi	a5,s1,15
    80003b02:	079a                	slli	a5,a5,0x6
    80003b04:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b06:	00099783          	lh	a5,0(s3)
    80003b0a:	c3a1                	beqz	a5,80003b4a <ialloc+0x9c>
    brelse(bp);
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	a54080e7          	jalr	-1452(ra) # 80003560 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b14:	0485                	addi	s1,s1,1
    80003b16:	00ca2703          	lw	a4,12(s4)
    80003b1a:	0004879b          	sext.w	a5,s1
    80003b1e:	fce7e1e3          	bltu	a5,a4,80003ae0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b22:	00005517          	auipc	a0,0x5
    80003b26:	abe50513          	addi	a0,a0,-1346 # 800085e0 <syscalls+0x188>
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	a5e080e7          	jalr	-1442(ra) # 80000588 <printf>
  return 0;
    80003b32:	4501                	li	a0,0
}
    80003b34:	60a6                	ld	ra,72(sp)
    80003b36:	6406                	ld	s0,64(sp)
    80003b38:	74e2                	ld	s1,56(sp)
    80003b3a:	7942                	ld	s2,48(sp)
    80003b3c:	79a2                	ld	s3,40(sp)
    80003b3e:	7a02                	ld	s4,32(sp)
    80003b40:	6ae2                	ld	s5,24(sp)
    80003b42:	6b42                	ld	s6,16(sp)
    80003b44:	6ba2                	ld	s7,8(sp)
    80003b46:	6161                	addi	sp,sp,80
    80003b48:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b4a:	04000613          	li	a2,64
    80003b4e:	4581                	li	a1,0
    80003b50:	854e                	mv	a0,s3
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	180080e7          	jalr	384(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b5a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b5e:	854a                	mv	a0,s2
    80003b60:	00001097          	auipc	ra,0x1
    80003b64:	c84080e7          	jalr	-892(ra) # 800047e4 <log_write>
      brelse(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	9f6080e7          	jalr	-1546(ra) # 80003560 <brelse>
      return iget(dev, inum);
    80003b72:	85da                	mv	a1,s6
    80003b74:	8556                	mv	a0,s5
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	d9c080e7          	jalr	-612(ra) # 80003912 <iget>
    80003b7e:	bf5d                	j	80003b34 <ialloc+0x86>

0000000080003b80 <iupdate>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	e04a                	sd	s2,0(sp)
    80003b8a:	1000                	addi	s0,sp,32
    80003b8c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b8e:	415c                	lw	a5,4(a0)
    80003b90:	0047d79b          	srliw	a5,a5,0x4
    80003b94:	0001e597          	auipc	a1,0x1e
    80003b98:	f0c5a583          	lw	a1,-244(a1) # 80021aa0 <sb+0x18>
    80003b9c:	9dbd                	addw	a1,a1,a5
    80003b9e:	4108                	lw	a0,0(a0)
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	890080e7          	jalr	-1904(ra) # 80003430 <bread>
    80003ba8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003baa:	05850793          	addi	a5,a0,88
    80003bae:	40c8                	lw	a0,4(s1)
    80003bb0:	893d                	andi	a0,a0,15
    80003bb2:	051a                	slli	a0,a0,0x6
    80003bb4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bb6:	04449703          	lh	a4,68(s1)
    80003bba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bbe:	04649703          	lh	a4,70(s1)
    80003bc2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bc6:	04849703          	lh	a4,72(s1)
    80003bca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bce:	04a49703          	lh	a4,74(s1)
    80003bd2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bd6:	44f8                	lw	a4,76(s1)
    80003bd8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bda:	03400613          	li	a2,52
    80003bde:	05048593          	addi	a1,s1,80
    80003be2:	0531                	addi	a0,a0,12
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	14a080e7          	jalr	330(ra) # 80000d2e <memmove>
  log_write(bp);
    80003bec:	854a                	mv	a0,s2
    80003bee:	00001097          	auipc	ra,0x1
    80003bf2:	bf6080e7          	jalr	-1034(ra) # 800047e4 <log_write>
  brelse(bp);
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	968080e7          	jalr	-1688(ra) # 80003560 <brelse>
}
    80003c00:	60e2                	ld	ra,24(sp)
    80003c02:	6442                	ld	s0,16(sp)
    80003c04:	64a2                	ld	s1,8(sp)
    80003c06:	6902                	ld	s2,0(sp)
    80003c08:	6105                	addi	sp,sp,32
    80003c0a:	8082                	ret

0000000080003c0c <idup>:
{
    80003c0c:	1101                	addi	sp,sp,-32
    80003c0e:	ec06                	sd	ra,24(sp)
    80003c10:	e822                	sd	s0,16(sp)
    80003c12:	e426                	sd	s1,8(sp)
    80003c14:	1000                	addi	s0,sp,32
    80003c16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c18:	0001e517          	auipc	a0,0x1e
    80003c1c:	e9050513          	addi	a0,a0,-368 # 80021aa8 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	fb6080e7          	jalr	-74(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c28:	449c                	lw	a5,8(s1)
    80003c2a:	2785                	addiw	a5,a5,1
    80003c2c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c2e:	0001e517          	auipc	a0,0x1e
    80003c32:	e7a50513          	addi	a0,a0,-390 # 80021aa8 <itable>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	054080e7          	jalr	84(ra) # 80000c8a <release>
}
    80003c3e:	8526                	mv	a0,s1
    80003c40:	60e2                	ld	ra,24(sp)
    80003c42:	6442                	ld	s0,16(sp)
    80003c44:	64a2                	ld	s1,8(sp)
    80003c46:	6105                	addi	sp,sp,32
    80003c48:	8082                	ret

0000000080003c4a <ilock>:
{
    80003c4a:	1101                	addi	sp,sp,-32
    80003c4c:	ec06                	sd	ra,24(sp)
    80003c4e:	e822                	sd	s0,16(sp)
    80003c50:	e426                	sd	s1,8(sp)
    80003c52:	e04a                	sd	s2,0(sp)
    80003c54:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c56:	c115                	beqz	a0,80003c7a <ilock+0x30>
    80003c58:	84aa                	mv	s1,a0
    80003c5a:	451c                	lw	a5,8(a0)
    80003c5c:	00f05f63          	blez	a5,80003c7a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c60:	0541                	addi	a0,a0,16
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	ca2080e7          	jalr	-862(ra) # 80004904 <acquiresleep>
  if(ip->valid == 0){
    80003c6a:	40bc                	lw	a5,64(s1)
    80003c6c:	cf99                	beqz	a5,80003c8a <ilock+0x40>
}
    80003c6e:	60e2                	ld	ra,24(sp)
    80003c70:	6442                	ld	s0,16(sp)
    80003c72:	64a2                	ld	s1,8(sp)
    80003c74:	6902                	ld	s2,0(sp)
    80003c76:	6105                	addi	sp,sp,32
    80003c78:	8082                	ret
    panic("ilock");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	97e50513          	addi	a0,a0,-1666 # 800085f8 <syscalls+0x1a0>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c8a:	40dc                	lw	a5,4(s1)
    80003c8c:	0047d79b          	srliw	a5,a5,0x4
    80003c90:	0001e597          	auipc	a1,0x1e
    80003c94:	e105a583          	lw	a1,-496(a1) # 80021aa0 <sb+0x18>
    80003c98:	9dbd                	addw	a1,a1,a5
    80003c9a:	4088                	lw	a0,0(s1)
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	794080e7          	jalr	1940(ra) # 80003430 <bread>
    80003ca4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ca6:	05850593          	addi	a1,a0,88
    80003caa:	40dc                	lw	a5,4(s1)
    80003cac:	8bbd                	andi	a5,a5,15
    80003cae:	079a                	slli	a5,a5,0x6
    80003cb0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cb2:	00059783          	lh	a5,0(a1)
    80003cb6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cba:	00259783          	lh	a5,2(a1)
    80003cbe:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cc2:	00459783          	lh	a5,4(a1)
    80003cc6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cca:	00659783          	lh	a5,6(a1)
    80003cce:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cd2:	459c                	lw	a5,8(a1)
    80003cd4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cd6:	03400613          	li	a2,52
    80003cda:	05b1                	addi	a1,a1,12
    80003cdc:	05048513          	addi	a0,s1,80
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	04e080e7          	jalr	78(ra) # 80000d2e <memmove>
    brelse(bp);
    80003ce8:	854a                	mv	a0,s2
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	876080e7          	jalr	-1930(ra) # 80003560 <brelse>
    ip->valid = 1;
    80003cf2:	4785                	li	a5,1
    80003cf4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cf6:	04449783          	lh	a5,68(s1)
    80003cfa:	fbb5                	bnez	a5,80003c6e <ilock+0x24>
      panic("ilock: no type");
    80003cfc:	00005517          	auipc	a0,0x5
    80003d00:	90450513          	addi	a0,a0,-1788 # 80008600 <syscalls+0x1a8>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>

0000000080003d0c <iunlock>:
{
    80003d0c:	1101                	addi	sp,sp,-32
    80003d0e:	ec06                	sd	ra,24(sp)
    80003d10:	e822                	sd	s0,16(sp)
    80003d12:	e426                	sd	s1,8(sp)
    80003d14:	e04a                	sd	s2,0(sp)
    80003d16:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d18:	c905                	beqz	a0,80003d48 <iunlock+0x3c>
    80003d1a:	84aa                	mv	s1,a0
    80003d1c:	01050913          	addi	s2,a0,16
    80003d20:	854a                	mv	a0,s2
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	c7c080e7          	jalr	-900(ra) # 8000499e <holdingsleep>
    80003d2a:	cd19                	beqz	a0,80003d48 <iunlock+0x3c>
    80003d2c:	449c                	lw	a5,8(s1)
    80003d2e:	00f05d63          	blez	a5,80003d48 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d32:	854a                	mv	a0,s2
    80003d34:	00001097          	auipc	ra,0x1
    80003d38:	c26080e7          	jalr	-986(ra) # 8000495a <releasesleep>
}
    80003d3c:	60e2                	ld	ra,24(sp)
    80003d3e:	6442                	ld	s0,16(sp)
    80003d40:	64a2                	ld	s1,8(sp)
    80003d42:	6902                	ld	s2,0(sp)
    80003d44:	6105                	addi	sp,sp,32
    80003d46:	8082                	ret
    panic("iunlock");
    80003d48:	00005517          	auipc	a0,0x5
    80003d4c:	8c850513          	addi	a0,a0,-1848 # 80008610 <syscalls+0x1b8>
    80003d50:	ffffc097          	auipc	ra,0xffffc
    80003d54:	7ee080e7          	jalr	2030(ra) # 8000053e <panic>

0000000080003d58 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d58:	7179                	addi	sp,sp,-48
    80003d5a:	f406                	sd	ra,40(sp)
    80003d5c:	f022                	sd	s0,32(sp)
    80003d5e:	ec26                	sd	s1,24(sp)
    80003d60:	e84a                	sd	s2,16(sp)
    80003d62:	e44e                	sd	s3,8(sp)
    80003d64:	e052                	sd	s4,0(sp)
    80003d66:	1800                	addi	s0,sp,48
    80003d68:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d6a:	05050493          	addi	s1,a0,80
    80003d6e:	08050913          	addi	s2,a0,128
    80003d72:	a021                	j	80003d7a <itrunc+0x22>
    80003d74:	0491                	addi	s1,s1,4
    80003d76:	01248d63          	beq	s1,s2,80003d90 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d7a:	408c                	lw	a1,0(s1)
    80003d7c:	dde5                	beqz	a1,80003d74 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d7e:	0009a503          	lw	a0,0(s3)
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	8f4080e7          	jalr	-1804(ra) # 80003676 <bfree>
      ip->addrs[i] = 0;
    80003d8a:	0004a023          	sw	zero,0(s1)
    80003d8e:	b7dd                	j	80003d74 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d90:	0809a583          	lw	a1,128(s3)
    80003d94:	e185                	bnez	a1,80003db4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d96:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d9a:	854e                	mv	a0,s3
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	de4080e7          	jalr	-540(ra) # 80003b80 <iupdate>
}
    80003da4:	70a2                	ld	ra,40(sp)
    80003da6:	7402                	ld	s0,32(sp)
    80003da8:	64e2                	ld	s1,24(sp)
    80003daa:	6942                	ld	s2,16(sp)
    80003dac:	69a2                	ld	s3,8(sp)
    80003dae:	6a02                	ld	s4,0(sp)
    80003db0:	6145                	addi	sp,sp,48
    80003db2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003db4:	0009a503          	lw	a0,0(s3)
    80003db8:	fffff097          	auipc	ra,0xfffff
    80003dbc:	678080e7          	jalr	1656(ra) # 80003430 <bread>
    80003dc0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dc2:	05850493          	addi	s1,a0,88
    80003dc6:	45850913          	addi	s2,a0,1112
    80003dca:	a021                	j	80003dd2 <itrunc+0x7a>
    80003dcc:	0491                	addi	s1,s1,4
    80003dce:	01248b63          	beq	s1,s2,80003de4 <itrunc+0x8c>
      if(a[j])
    80003dd2:	408c                	lw	a1,0(s1)
    80003dd4:	dde5                	beqz	a1,80003dcc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dd6:	0009a503          	lw	a0,0(s3)
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	89c080e7          	jalr	-1892(ra) # 80003676 <bfree>
    80003de2:	b7ed                	j	80003dcc <itrunc+0x74>
    brelse(bp);
    80003de4:	8552                	mv	a0,s4
    80003de6:	fffff097          	auipc	ra,0xfffff
    80003dea:	77a080e7          	jalr	1914(ra) # 80003560 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dee:	0809a583          	lw	a1,128(s3)
    80003df2:	0009a503          	lw	a0,0(s3)
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	880080e7          	jalr	-1920(ra) # 80003676 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dfe:	0809a023          	sw	zero,128(s3)
    80003e02:	bf51                	j	80003d96 <itrunc+0x3e>

0000000080003e04 <iput>:
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	e426                	sd	s1,8(sp)
    80003e0c:	e04a                	sd	s2,0(sp)
    80003e0e:	1000                	addi	s0,sp,32
    80003e10:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e12:	0001e517          	auipc	a0,0x1e
    80003e16:	c9650513          	addi	a0,a0,-874 # 80021aa8 <itable>
    80003e1a:	ffffd097          	auipc	ra,0xffffd
    80003e1e:	dbc080e7          	jalr	-580(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e22:	4498                	lw	a4,8(s1)
    80003e24:	4785                	li	a5,1
    80003e26:	02f70363          	beq	a4,a5,80003e4c <iput+0x48>
  ip->ref--;
    80003e2a:	449c                	lw	a5,8(s1)
    80003e2c:	37fd                	addiw	a5,a5,-1
    80003e2e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e30:	0001e517          	auipc	a0,0x1e
    80003e34:	c7850513          	addi	a0,a0,-904 # 80021aa8 <itable>
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	e52080e7          	jalr	-430(ra) # 80000c8a <release>
}
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6902                	ld	s2,0(sp)
    80003e48:	6105                	addi	sp,sp,32
    80003e4a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e4c:	40bc                	lw	a5,64(s1)
    80003e4e:	dff1                	beqz	a5,80003e2a <iput+0x26>
    80003e50:	04a49783          	lh	a5,74(s1)
    80003e54:	fbf9                	bnez	a5,80003e2a <iput+0x26>
    acquiresleep(&ip->lock);
    80003e56:	01048913          	addi	s2,s1,16
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00001097          	auipc	ra,0x1
    80003e60:	aa8080e7          	jalr	-1368(ra) # 80004904 <acquiresleep>
    release(&itable.lock);
    80003e64:	0001e517          	auipc	a0,0x1e
    80003e68:	c4450513          	addi	a0,a0,-956 # 80021aa8 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
    itrunc(ip);
    80003e74:	8526                	mv	a0,s1
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	ee2080e7          	jalr	-286(ra) # 80003d58 <itrunc>
    ip->type = 0;
    80003e7e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e82:	8526                	mv	a0,s1
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	cfc080e7          	jalr	-772(ra) # 80003b80 <iupdate>
    ip->valid = 0;
    80003e8c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e90:	854a                	mv	a0,s2
    80003e92:	00001097          	auipc	ra,0x1
    80003e96:	ac8080e7          	jalr	-1336(ra) # 8000495a <releasesleep>
    acquire(&itable.lock);
    80003e9a:	0001e517          	auipc	a0,0x1e
    80003e9e:	c0e50513          	addi	a0,a0,-1010 # 80021aa8 <itable>
    80003ea2:	ffffd097          	auipc	ra,0xffffd
    80003ea6:	d34080e7          	jalr	-716(ra) # 80000bd6 <acquire>
    80003eaa:	b741                	j	80003e2a <iput+0x26>

0000000080003eac <iunlockput>:
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	1000                	addi	s0,sp,32
    80003eb6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	e54080e7          	jalr	-428(ra) # 80003d0c <iunlock>
  iput(ip);
    80003ec0:	8526                	mv	a0,s1
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	f42080e7          	jalr	-190(ra) # 80003e04 <iput>
}
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	64a2                	ld	s1,8(sp)
    80003ed0:	6105                	addi	sp,sp,32
    80003ed2:	8082                	ret

0000000080003ed4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ed4:	1141                	addi	sp,sp,-16
    80003ed6:	e422                	sd	s0,8(sp)
    80003ed8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eda:	411c                	lw	a5,0(a0)
    80003edc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ede:	415c                	lw	a5,4(a0)
    80003ee0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ee2:	04451783          	lh	a5,68(a0)
    80003ee6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eea:	04a51783          	lh	a5,74(a0)
    80003eee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ef2:	04c56783          	lwu	a5,76(a0)
    80003ef6:	e99c                	sd	a5,16(a1)
}
    80003ef8:	6422                	ld	s0,8(sp)
    80003efa:	0141                	addi	sp,sp,16
    80003efc:	8082                	ret

0000000080003efe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003efe:	457c                	lw	a5,76(a0)
    80003f00:	0ed7e963          	bltu	a5,a3,80003ff2 <readi+0xf4>
{
    80003f04:	7159                	addi	sp,sp,-112
    80003f06:	f486                	sd	ra,104(sp)
    80003f08:	f0a2                	sd	s0,96(sp)
    80003f0a:	eca6                	sd	s1,88(sp)
    80003f0c:	e8ca                	sd	s2,80(sp)
    80003f0e:	e4ce                	sd	s3,72(sp)
    80003f10:	e0d2                	sd	s4,64(sp)
    80003f12:	fc56                	sd	s5,56(sp)
    80003f14:	f85a                	sd	s6,48(sp)
    80003f16:	f45e                	sd	s7,40(sp)
    80003f18:	f062                	sd	s8,32(sp)
    80003f1a:	ec66                	sd	s9,24(sp)
    80003f1c:	e86a                	sd	s10,16(sp)
    80003f1e:	e46e                	sd	s11,8(sp)
    80003f20:	1880                	addi	s0,sp,112
    80003f22:	8b2a                	mv	s6,a0
    80003f24:	8bae                	mv	s7,a1
    80003f26:	8a32                	mv	s4,a2
    80003f28:	84b6                	mv	s1,a3
    80003f2a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f2c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f2e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f30:	0ad76063          	bltu	a4,a3,80003fd0 <readi+0xd2>
  if(off + n > ip->size)
    80003f34:	00e7f463          	bgeu	a5,a4,80003f3c <readi+0x3e>
    n = ip->size - off;
    80003f38:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f3c:	0a0a8963          	beqz	s5,80003fee <readi+0xf0>
    80003f40:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f42:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f46:	5c7d                	li	s8,-1
    80003f48:	a82d                	j	80003f82 <readi+0x84>
    80003f4a:	020d1d93          	slli	s11,s10,0x20
    80003f4e:	020ddd93          	srli	s11,s11,0x20
    80003f52:	05890793          	addi	a5,s2,88
    80003f56:	86ee                	mv	a3,s11
    80003f58:	963e                	add	a2,a2,a5
    80003f5a:	85d2                	mv	a1,s4
    80003f5c:	855e                	mv	a0,s7
    80003f5e:	ffffe097          	auipc	ra,0xffffe
    80003f62:	748080e7          	jalr	1864(ra) # 800026a6 <either_copyout>
    80003f66:	05850d63          	beq	a0,s8,80003fc0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	5f4080e7          	jalr	1524(ra) # 80003560 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f74:	013d09bb          	addw	s3,s10,s3
    80003f78:	009d04bb          	addw	s1,s10,s1
    80003f7c:	9a6e                	add	s4,s4,s11
    80003f7e:	0559f763          	bgeu	s3,s5,80003fcc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f82:	00a4d59b          	srliw	a1,s1,0xa
    80003f86:	855a                	mv	a0,s6
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	8a2080e7          	jalr	-1886(ra) # 8000382a <bmap>
    80003f90:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f94:	cd85                	beqz	a1,80003fcc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f96:	000b2503          	lw	a0,0(s6)
    80003f9a:	fffff097          	auipc	ra,0xfffff
    80003f9e:	496080e7          	jalr	1174(ra) # 80003430 <bread>
    80003fa2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa4:	3ff4f613          	andi	a2,s1,1023
    80003fa8:	40cc87bb          	subw	a5,s9,a2
    80003fac:	413a873b          	subw	a4,s5,s3
    80003fb0:	8d3e                	mv	s10,a5
    80003fb2:	2781                	sext.w	a5,a5
    80003fb4:	0007069b          	sext.w	a3,a4
    80003fb8:	f8f6f9e3          	bgeu	a3,a5,80003f4a <readi+0x4c>
    80003fbc:	8d3a                	mv	s10,a4
    80003fbe:	b771                	j	80003f4a <readi+0x4c>
      brelse(bp);
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	59e080e7          	jalr	1438(ra) # 80003560 <brelse>
      tot = -1;
    80003fca:	59fd                	li	s3,-1
  }
  return tot;
    80003fcc:	0009851b          	sext.w	a0,s3
}
    80003fd0:	70a6                	ld	ra,104(sp)
    80003fd2:	7406                	ld	s0,96(sp)
    80003fd4:	64e6                	ld	s1,88(sp)
    80003fd6:	6946                	ld	s2,80(sp)
    80003fd8:	69a6                	ld	s3,72(sp)
    80003fda:	6a06                	ld	s4,64(sp)
    80003fdc:	7ae2                	ld	s5,56(sp)
    80003fde:	7b42                	ld	s6,48(sp)
    80003fe0:	7ba2                	ld	s7,40(sp)
    80003fe2:	7c02                	ld	s8,32(sp)
    80003fe4:	6ce2                	ld	s9,24(sp)
    80003fe6:	6d42                	ld	s10,16(sp)
    80003fe8:	6da2                	ld	s11,8(sp)
    80003fea:	6165                	addi	sp,sp,112
    80003fec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fee:	89d6                	mv	s3,s5
    80003ff0:	bff1                	j	80003fcc <readi+0xce>
    return 0;
    80003ff2:	4501                	li	a0,0
}
    80003ff4:	8082                	ret

0000000080003ff6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ff6:	457c                	lw	a5,76(a0)
    80003ff8:	10d7e863          	bltu	a5,a3,80004108 <writei+0x112>
{
    80003ffc:	7159                	addi	sp,sp,-112
    80003ffe:	f486                	sd	ra,104(sp)
    80004000:	f0a2                	sd	s0,96(sp)
    80004002:	eca6                	sd	s1,88(sp)
    80004004:	e8ca                	sd	s2,80(sp)
    80004006:	e4ce                	sd	s3,72(sp)
    80004008:	e0d2                	sd	s4,64(sp)
    8000400a:	fc56                	sd	s5,56(sp)
    8000400c:	f85a                	sd	s6,48(sp)
    8000400e:	f45e                	sd	s7,40(sp)
    80004010:	f062                	sd	s8,32(sp)
    80004012:	ec66                	sd	s9,24(sp)
    80004014:	e86a                	sd	s10,16(sp)
    80004016:	e46e                	sd	s11,8(sp)
    80004018:	1880                	addi	s0,sp,112
    8000401a:	8aaa                	mv	s5,a0
    8000401c:	8bae                	mv	s7,a1
    8000401e:	8a32                	mv	s4,a2
    80004020:	8936                	mv	s2,a3
    80004022:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004024:	00e687bb          	addw	a5,a3,a4
    80004028:	0ed7e263          	bltu	a5,a3,8000410c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000402c:	00043737          	lui	a4,0x43
    80004030:	0ef76063          	bltu	a4,a5,80004110 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004034:	0c0b0863          	beqz	s6,80004104 <writei+0x10e>
    80004038:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000403a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000403e:	5c7d                	li	s8,-1
    80004040:	a091                	j	80004084 <writei+0x8e>
    80004042:	020d1d93          	slli	s11,s10,0x20
    80004046:	020ddd93          	srli	s11,s11,0x20
    8000404a:	05848793          	addi	a5,s1,88
    8000404e:	86ee                	mv	a3,s11
    80004050:	8652                	mv	a2,s4
    80004052:	85de                	mv	a1,s7
    80004054:	953e                	add	a0,a0,a5
    80004056:	ffffe097          	auipc	ra,0xffffe
    8000405a:	6a6080e7          	jalr	1702(ra) # 800026fc <either_copyin>
    8000405e:	07850263          	beq	a0,s8,800040c2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004062:	8526                	mv	a0,s1
    80004064:	00000097          	auipc	ra,0x0
    80004068:	780080e7          	jalr	1920(ra) # 800047e4 <log_write>
    brelse(bp);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	4f2080e7          	jalr	1266(ra) # 80003560 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004076:	013d09bb          	addw	s3,s10,s3
    8000407a:	012d093b          	addw	s2,s10,s2
    8000407e:	9a6e                	add	s4,s4,s11
    80004080:	0569f663          	bgeu	s3,s6,800040cc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004084:	00a9559b          	srliw	a1,s2,0xa
    80004088:	8556                	mv	a0,s5
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	7a0080e7          	jalr	1952(ra) # 8000382a <bmap>
    80004092:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004096:	c99d                	beqz	a1,800040cc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004098:	000aa503          	lw	a0,0(s5)
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	394080e7          	jalr	916(ra) # 80003430 <bread>
    800040a4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a6:	3ff97513          	andi	a0,s2,1023
    800040aa:	40ac87bb          	subw	a5,s9,a0
    800040ae:	413b073b          	subw	a4,s6,s3
    800040b2:	8d3e                	mv	s10,a5
    800040b4:	2781                	sext.w	a5,a5
    800040b6:	0007069b          	sext.w	a3,a4
    800040ba:	f8f6f4e3          	bgeu	a3,a5,80004042 <writei+0x4c>
    800040be:	8d3a                	mv	s10,a4
    800040c0:	b749                	j	80004042 <writei+0x4c>
      brelse(bp);
    800040c2:	8526                	mv	a0,s1
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	49c080e7          	jalr	1180(ra) # 80003560 <brelse>
  }

  if(off > ip->size)
    800040cc:	04caa783          	lw	a5,76(s5)
    800040d0:	0127f463          	bgeu	a5,s2,800040d8 <writei+0xe2>
    ip->size = off;
    800040d4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040d8:	8556                	mv	a0,s5
    800040da:	00000097          	auipc	ra,0x0
    800040de:	aa6080e7          	jalr	-1370(ra) # 80003b80 <iupdate>

  return tot;
    800040e2:	0009851b          	sext.w	a0,s3
}
    800040e6:	70a6                	ld	ra,104(sp)
    800040e8:	7406                	ld	s0,96(sp)
    800040ea:	64e6                	ld	s1,88(sp)
    800040ec:	6946                	ld	s2,80(sp)
    800040ee:	69a6                	ld	s3,72(sp)
    800040f0:	6a06                	ld	s4,64(sp)
    800040f2:	7ae2                	ld	s5,56(sp)
    800040f4:	7b42                	ld	s6,48(sp)
    800040f6:	7ba2                	ld	s7,40(sp)
    800040f8:	7c02                	ld	s8,32(sp)
    800040fa:	6ce2                	ld	s9,24(sp)
    800040fc:	6d42                	ld	s10,16(sp)
    800040fe:	6da2                	ld	s11,8(sp)
    80004100:	6165                	addi	sp,sp,112
    80004102:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004104:	89da                	mv	s3,s6
    80004106:	bfc9                	j	800040d8 <writei+0xe2>
    return -1;
    80004108:	557d                	li	a0,-1
}
    8000410a:	8082                	ret
    return -1;
    8000410c:	557d                	li	a0,-1
    8000410e:	bfe1                	j	800040e6 <writei+0xf0>
    return -1;
    80004110:	557d                	li	a0,-1
    80004112:	bfd1                	j	800040e6 <writei+0xf0>

0000000080004114 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004114:	1141                	addi	sp,sp,-16
    80004116:	e406                	sd	ra,8(sp)
    80004118:	e022                	sd	s0,0(sp)
    8000411a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000411c:	4639                	li	a2,14
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	c84080e7          	jalr	-892(ra) # 80000da2 <strncmp>
}
    80004126:	60a2                	ld	ra,8(sp)
    80004128:	6402                	ld	s0,0(sp)
    8000412a:	0141                	addi	sp,sp,16
    8000412c:	8082                	ret

000000008000412e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000412e:	7139                	addi	sp,sp,-64
    80004130:	fc06                	sd	ra,56(sp)
    80004132:	f822                	sd	s0,48(sp)
    80004134:	f426                	sd	s1,40(sp)
    80004136:	f04a                	sd	s2,32(sp)
    80004138:	ec4e                	sd	s3,24(sp)
    8000413a:	e852                	sd	s4,16(sp)
    8000413c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000413e:	04451703          	lh	a4,68(a0)
    80004142:	4785                	li	a5,1
    80004144:	00f71a63          	bne	a4,a5,80004158 <dirlookup+0x2a>
    80004148:	892a                	mv	s2,a0
    8000414a:	89ae                	mv	s3,a1
    8000414c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000414e:	457c                	lw	a5,76(a0)
    80004150:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004152:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004154:	e79d                	bnez	a5,80004182 <dirlookup+0x54>
    80004156:	a8a5                	j	800041ce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004158:	00004517          	auipc	a0,0x4
    8000415c:	4c050513          	addi	a0,a0,1216 # 80008618 <syscalls+0x1c0>
    80004160:	ffffc097          	auipc	ra,0xffffc
    80004164:	3de080e7          	jalr	990(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004168:	00004517          	auipc	a0,0x4
    8000416c:	4c850513          	addi	a0,a0,1224 # 80008630 <syscalls+0x1d8>
    80004170:	ffffc097          	auipc	ra,0xffffc
    80004174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004178:	24c1                	addiw	s1,s1,16
    8000417a:	04c92783          	lw	a5,76(s2)
    8000417e:	04f4f763          	bgeu	s1,a5,800041cc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004182:	4741                	li	a4,16
    80004184:	86a6                	mv	a3,s1
    80004186:	fc040613          	addi	a2,s0,-64
    8000418a:	4581                	li	a1,0
    8000418c:	854a                	mv	a0,s2
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	d70080e7          	jalr	-656(ra) # 80003efe <readi>
    80004196:	47c1                	li	a5,16
    80004198:	fcf518e3          	bne	a0,a5,80004168 <dirlookup+0x3a>
    if(de.inum == 0)
    8000419c:	fc045783          	lhu	a5,-64(s0)
    800041a0:	dfe1                	beqz	a5,80004178 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041a2:	fc240593          	addi	a1,s0,-62
    800041a6:	854e                	mv	a0,s3
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	f6c080e7          	jalr	-148(ra) # 80004114 <namecmp>
    800041b0:	f561                	bnez	a0,80004178 <dirlookup+0x4a>
      if(poff)
    800041b2:	000a0463          	beqz	s4,800041ba <dirlookup+0x8c>
        *poff = off;
    800041b6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ba:	fc045583          	lhu	a1,-64(s0)
    800041be:	00092503          	lw	a0,0(s2)
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	750080e7          	jalr	1872(ra) # 80003912 <iget>
    800041ca:	a011                	j	800041ce <dirlookup+0xa0>
  return 0;
    800041cc:	4501                	li	a0,0
}
    800041ce:	70e2                	ld	ra,56(sp)
    800041d0:	7442                	ld	s0,48(sp)
    800041d2:	74a2                	ld	s1,40(sp)
    800041d4:	7902                	ld	s2,32(sp)
    800041d6:	69e2                	ld	s3,24(sp)
    800041d8:	6a42                	ld	s4,16(sp)
    800041da:	6121                	addi	sp,sp,64
    800041dc:	8082                	ret

00000000800041de <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041de:	711d                	addi	sp,sp,-96
    800041e0:	ec86                	sd	ra,88(sp)
    800041e2:	e8a2                	sd	s0,80(sp)
    800041e4:	e4a6                	sd	s1,72(sp)
    800041e6:	e0ca                	sd	s2,64(sp)
    800041e8:	fc4e                	sd	s3,56(sp)
    800041ea:	f852                	sd	s4,48(sp)
    800041ec:	f456                	sd	s5,40(sp)
    800041ee:	f05a                	sd	s6,32(sp)
    800041f0:	ec5e                	sd	s7,24(sp)
    800041f2:	e862                	sd	s8,16(sp)
    800041f4:	e466                	sd	s9,8(sp)
    800041f6:	1080                	addi	s0,sp,96
    800041f8:	84aa                	mv	s1,a0
    800041fa:	8aae                	mv	s5,a1
    800041fc:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041fe:	00054703          	lbu	a4,0(a0)
    80004202:	02f00793          	li	a5,47
    80004206:	02f70363          	beq	a4,a5,8000422c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000420a:	ffffe097          	auipc	ra,0xffffe
    8000420e:	888080e7          	jalr	-1912(ra) # 80001a92 <myproc>
    80004212:	15853503          	ld	a0,344(a0)
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	9f6080e7          	jalr	-1546(ra) # 80003c0c <idup>
    8000421e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004220:	02f00913          	li	s2,47
  len = path - s;
    80004224:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004226:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004228:	4b85                	li	s7,1
    8000422a:	a865                	j	800042e2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000422c:	4585                	li	a1,1
    8000422e:	4505                	li	a0,1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	6e2080e7          	jalr	1762(ra) # 80003912 <iget>
    80004238:	89aa                	mv	s3,a0
    8000423a:	b7dd                	j	80004220 <namex+0x42>
      iunlockput(ip);
    8000423c:	854e                	mv	a0,s3
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	c6e080e7          	jalr	-914(ra) # 80003eac <iunlockput>
      return 0;
    80004246:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004248:	854e                	mv	a0,s3
    8000424a:	60e6                	ld	ra,88(sp)
    8000424c:	6446                	ld	s0,80(sp)
    8000424e:	64a6                	ld	s1,72(sp)
    80004250:	6906                	ld	s2,64(sp)
    80004252:	79e2                	ld	s3,56(sp)
    80004254:	7a42                	ld	s4,48(sp)
    80004256:	7aa2                	ld	s5,40(sp)
    80004258:	7b02                	ld	s6,32(sp)
    8000425a:	6be2                	ld	s7,24(sp)
    8000425c:	6c42                	ld	s8,16(sp)
    8000425e:	6ca2                	ld	s9,8(sp)
    80004260:	6125                	addi	sp,sp,96
    80004262:	8082                	ret
      iunlock(ip);
    80004264:	854e                	mv	a0,s3
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	aa6080e7          	jalr	-1370(ra) # 80003d0c <iunlock>
      return ip;
    8000426e:	bfe9                	j	80004248 <namex+0x6a>
      iunlockput(ip);
    80004270:	854e                	mv	a0,s3
    80004272:	00000097          	auipc	ra,0x0
    80004276:	c3a080e7          	jalr	-966(ra) # 80003eac <iunlockput>
      return 0;
    8000427a:	89e6                	mv	s3,s9
    8000427c:	b7f1                	j	80004248 <namex+0x6a>
  len = path - s;
    8000427e:	40b48633          	sub	a2,s1,a1
    80004282:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004286:	099c5463          	bge	s8,s9,8000430e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000428a:	4639                	li	a2,14
    8000428c:	8552                	mv	a0,s4
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	aa0080e7          	jalr	-1376(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	01279763          	bne	a5,s2,800042a8 <namex+0xca>
    path++;
    8000429e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042a0:	0004c783          	lbu	a5,0(s1)
    800042a4:	ff278de3          	beq	a5,s2,8000429e <namex+0xc0>
    ilock(ip);
    800042a8:	854e                	mv	a0,s3
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	9a0080e7          	jalr	-1632(ra) # 80003c4a <ilock>
    if(ip->type != T_DIR){
    800042b2:	04499783          	lh	a5,68(s3)
    800042b6:	f97793e3          	bne	a5,s7,8000423c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ba:	000a8563          	beqz	s5,800042c4 <namex+0xe6>
    800042be:	0004c783          	lbu	a5,0(s1)
    800042c2:	d3cd                	beqz	a5,80004264 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042c4:	865a                	mv	a2,s6
    800042c6:	85d2                	mv	a1,s4
    800042c8:	854e                	mv	a0,s3
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	e64080e7          	jalr	-412(ra) # 8000412e <dirlookup>
    800042d2:	8caa                	mv	s9,a0
    800042d4:	dd51                	beqz	a0,80004270 <namex+0x92>
    iunlockput(ip);
    800042d6:	854e                	mv	a0,s3
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	bd4080e7          	jalr	-1068(ra) # 80003eac <iunlockput>
    ip = next;
    800042e0:	89e6                	mv	s3,s9
  while(*path == '/')
    800042e2:	0004c783          	lbu	a5,0(s1)
    800042e6:	05279763          	bne	a5,s2,80004334 <namex+0x156>
    path++;
    800042ea:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ec:	0004c783          	lbu	a5,0(s1)
    800042f0:	ff278de3          	beq	a5,s2,800042ea <namex+0x10c>
  if(*path == 0)
    800042f4:	c79d                	beqz	a5,80004322 <namex+0x144>
    path++;
    800042f6:	85a6                	mv	a1,s1
  len = path - s;
    800042f8:	8cda                	mv	s9,s6
    800042fa:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800042fc:	01278963          	beq	a5,s2,8000430e <namex+0x130>
    80004300:	dfbd                	beqz	a5,8000427e <namex+0xa0>
    path++;
    80004302:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004304:	0004c783          	lbu	a5,0(s1)
    80004308:	ff279ce3          	bne	a5,s2,80004300 <namex+0x122>
    8000430c:	bf8d                	j	8000427e <namex+0xa0>
    memmove(name, s, len);
    8000430e:	2601                	sext.w	a2,a2
    80004310:	8552                	mv	a0,s4
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	a1c080e7          	jalr	-1508(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000431a:	9cd2                	add	s9,s9,s4
    8000431c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004320:	bf9d                	j	80004296 <namex+0xb8>
  if(nameiparent){
    80004322:	f20a83e3          	beqz	s5,80004248 <namex+0x6a>
    iput(ip);
    80004326:	854e                	mv	a0,s3
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	adc080e7          	jalr	-1316(ra) # 80003e04 <iput>
    return 0;
    80004330:	4981                	li	s3,0
    80004332:	bf19                	j	80004248 <namex+0x6a>
  if(*path == 0)
    80004334:	d7fd                	beqz	a5,80004322 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004336:	0004c783          	lbu	a5,0(s1)
    8000433a:	85a6                	mv	a1,s1
    8000433c:	b7d1                	j	80004300 <namex+0x122>

000000008000433e <dirlink>:
{
    8000433e:	7139                	addi	sp,sp,-64
    80004340:	fc06                	sd	ra,56(sp)
    80004342:	f822                	sd	s0,48(sp)
    80004344:	f426                	sd	s1,40(sp)
    80004346:	f04a                	sd	s2,32(sp)
    80004348:	ec4e                	sd	s3,24(sp)
    8000434a:	e852                	sd	s4,16(sp)
    8000434c:	0080                	addi	s0,sp,64
    8000434e:	892a                	mv	s2,a0
    80004350:	8a2e                	mv	s4,a1
    80004352:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004354:	4601                	li	a2,0
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	dd8080e7          	jalr	-552(ra) # 8000412e <dirlookup>
    8000435e:	e93d                	bnez	a0,800043d4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004360:	04c92483          	lw	s1,76(s2)
    80004364:	c49d                	beqz	s1,80004392 <dirlink+0x54>
    80004366:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004368:	4741                	li	a4,16
    8000436a:	86a6                	mv	a3,s1
    8000436c:	fc040613          	addi	a2,s0,-64
    80004370:	4581                	li	a1,0
    80004372:	854a                	mv	a0,s2
    80004374:	00000097          	auipc	ra,0x0
    80004378:	b8a080e7          	jalr	-1142(ra) # 80003efe <readi>
    8000437c:	47c1                	li	a5,16
    8000437e:	06f51163          	bne	a0,a5,800043e0 <dirlink+0xa2>
    if(de.inum == 0)
    80004382:	fc045783          	lhu	a5,-64(s0)
    80004386:	c791                	beqz	a5,80004392 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004388:	24c1                	addiw	s1,s1,16
    8000438a:	04c92783          	lw	a5,76(s2)
    8000438e:	fcf4ede3          	bltu	s1,a5,80004368 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004392:	4639                	li	a2,14
    80004394:	85d2                	mv	a1,s4
    80004396:	fc240513          	addi	a0,s0,-62
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	a44080e7          	jalr	-1468(ra) # 80000dde <strncpy>
  de.inum = inum;
    800043a2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a6:	4741                	li	a4,16
    800043a8:	86a6                	mv	a3,s1
    800043aa:	fc040613          	addi	a2,s0,-64
    800043ae:	4581                	li	a1,0
    800043b0:	854a                	mv	a0,s2
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	c44080e7          	jalr	-956(ra) # 80003ff6 <writei>
    800043ba:	1541                	addi	a0,a0,-16
    800043bc:	00a03533          	snez	a0,a0
    800043c0:	40a00533          	neg	a0,a0
}
    800043c4:	70e2                	ld	ra,56(sp)
    800043c6:	7442                	ld	s0,48(sp)
    800043c8:	74a2                	ld	s1,40(sp)
    800043ca:	7902                	ld	s2,32(sp)
    800043cc:	69e2                	ld	s3,24(sp)
    800043ce:	6a42                	ld	s4,16(sp)
    800043d0:	6121                	addi	sp,sp,64
    800043d2:	8082                	ret
    iput(ip);
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	a30080e7          	jalr	-1488(ra) # 80003e04 <iput>
    return -1;
    800043dc:	557d                	li	a0,-1
    800043de:	b7dd                	j	800043c4 <dirlink+0x86>
      panic("dirlink read");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	26050513          	addi	a0,a0,608 # 80008640 <syscalls+0x1e8>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	156080e7          	jalr	342(ra) # 8000053e <panic>

00000000800043f0 <namei>:

struct inode*
namei(char *path)
{
    800043f0:	1101                	addi	sp,sp,-32
    800043f2:	ec06                	sd	ra,24(sp)
    800043f4:	e822                	sd	s0,16(sp)
    800043f6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043f8:	fe040613          	addi	a2,s0,-32
    800043fc:	4581                	li	a1,0
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	de0080e7          	jalr	-544(ra) # 800041de <namex>
}
    80004406:	60e2                	ld	ra,24(sp)
    80004408:	6442                	ld	s0,16(sp)
    8000440a:	6105                	addi	sp,sp,32
    8000440c:	8082                	ret

000000008000440e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000440e:	1141                	addi	sp,sp,-16
    80004410:	e406                	sd	ra,8(sp)
    80004412:	e022                	sd	s0,0(sp)
    80004414:	0800                	addi	s0,sp,16
    80004416:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004418:	4585                	li	a1,1
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	dc4080e7          	jalr	-572(ra) # 800041de <namex>
}
    80004422:	60a2                	ld	ra,8(sp)
    80004424:	6402                	ld	s0,0(sp)
    80004426:	0141                	addi	sp,sp,16
    80004428:	8082                	ret

000000008000442a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	e04a                	sd	s2,0(sp)
    80004434:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004436:	0001f917          	auipc	s2,0x1f
    8000443a:	11a90913          	addi	s2,s2,282 # 80023550 <log>
    8000443e:	01892583          	lw	a1,24(s2)
    80004442:	02892503          	lw	a0,40(s2)
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	fea080e7          	jalr	-22(ra) # 80003430 <bread>
    8000444e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004450:	02c92683          	lw	a3,44(s2)
    80004454:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004456:	02d05763          	blez	a3,80004484 <write_head+0x5a>
    8000445a:	0001f797          	auipc	a5,0x1f
    8000445e:	12678793          	addi	a5,a5,294 # 80023580 <log+0x30>
    80004462:	05c50713          	addi	a4,a0,92
    80004466:	36fd                	addiw	a3,a3,-1
    80004468:	1682                	slli	a3,a3,0x20
    8000446a:	9281                	srli	a3,a3,0x20
    8000446c:	068a                	slli	a3,a3,0x2
    8000446e:	0001f617          	auipc	a2,0x1f
    80004472:	11660613          	addi	a2,a2,278 # 80023584 <log+0x34>
    80004476:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004478:	4390                	lw	a2,0(a5)
    8000447a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000447c:	0791                	addi	a5,a5,4
    8000447e:	0711                	addi	a4,a4,4
    80004480:	fed79ce3          	bne	a5,a3,80004478 <write_head+0x4e>
  }
  bwrite(buf);
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	09c080e7          	jalr	156(ra) # 80003522 <bwrite>
  brelse(buf);
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	0d0080e7          	jalr	208(ra) # 80003560 <brelse>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6902                	ld	s2,0(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a4:	0001f797          	auipc	a5,0x1f
    800044a8:	0d87a783          	lw	a5,216(a5) # 8002357c <log+0x2c>
    800044ac:	0af05d63          	blez	a5,80004566 <install_trans+0xc2>
{
    800044b0:	7139                	addi	sp,sp,-64
    800044b2:	fc06                	sd	ra,56(sp)
    800044b4:	f822                	sd	s0,48(sp)
    800044b6:	f426                	sd	s1,40(sp)
    800044b8:	f04a                	sd	s2,32(sp)
    800044ba:	ec4e                	sd	s3,24(sp)
    800044bc:	e852                	sd	s4,16(sp)
    800044be:	e456                	sd	s5,8(sp)
    800044c0:	e05a                	sd	s6,0(sp)
    800044c2:	0080                	addi	s0,sp,64
    800044c4:	8b2a                	mv	s6,a0
    800044c6:	0001fa97          	auipc	s5,0x1f
    800044ca:	0baa8a93          	addi	s5,s5,186 # 80023580 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d0:	0001f997          	auipc	s3,0x1f
    800044d4:	08098993          	addi	s3,s3,128 # 80023550 <log>
    800044d8:	a00d                	j	800044fa <install_trans+0x56>
    brelse(lbuf);
    800044da:	854a                	mv	a0,s2
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	084080e7          	jalr	132(ra) # 80003560 <brelse>
    brelse(dbuf);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	07a080e7          	jalr	122(ra) # 80003560 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ee:	2a05                	addiw	s4,s4,1
    800044f0:	0a91                	addi	s5,s5,4
    800044f2:	02c9a783          	lw	a5,44(s3)
    800044f6:	04fa5e63          	bge	s4,a5,80004552 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044fa:	0189a583          	lw	a1,24(s3)
    800044fe:	014585bb          	addw	a1,a1,s4
    80004502:	2585                	addiw	a1,a1,1
    80004504:	0289a503          	lw	a0,40(s3)
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	f28080e7          	jalr	-216(ra) # 80003430 <bread>
    80004510:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004512:	000aa583          	lw	a1,0(s5)
    80004516:	0289a503          	lw	a0,40(s3)
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	f16080e7          	jalr	-234(ra) # 80003430 <bread>
    80004522:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004524:	40000613          	li	a2,1024
    80004528:	05890593          	addi	a1,s2,88
    8000452c:	05850513          	addi	a0,a0,88
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	7fe080e7          	jalr	2046(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004538:	8526                	mv	a0,s1
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	fe8080e7          	jalr	-24(ra) # 80003522 <bwrite>
    if(recovering == 0)
    80004542:	f80b1ce3          	bnez	s6,800044da <install_trans+0x36>
      bunpin(dbuf);
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	0f2080e7          	jalr	242(ra) # 8000363a <bunpin>
    80004550:	b769                	j	800044da <install_trans+0x36>
}
    80004552:	70e2                	ld	ra,56(sp)
    80004554:	7442                	ld	s0,48(sp)
    80004556:	74a2                	ld	s1,40(sp)
    80004558:	7902                	ld	s2,32(sp)
    8000455a:	69e2                	ld	s3,24(sp)
    8000455c:	6a42                	ld	s4,16(sp)
    8000455e:	6aa2                	ld	s5,8(sp)
    80004560:	6b02                	ld	s6,0(sp)
    80004562:	6121                	addi	sp,sp,64
    80004564:	8082                	ret
    80004566:	8082                	ret

0000000080004568 <initlog>:
{
    80004568:	7179                	addi	sp,sp,-48
    8000456a:	f406                	sd	ra,40(sp)
    8000456c:	f022                	sd	s0,32(sp)
    8000456e:	ec26                	sd	s1,24(sp)
    80004570:	e84a                	sd	s2,16(sp)
    80004572:	e44e                	sd	s3,8(sp)
    80004574:	1800                	addi	s0,sp,48
    80004576:	892a                	mv	s2,a0
    80004578:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000457a:	0001f497          	auipc	s1,0x1f
    8000457e:	fd648493          	addi	s1,s1,-42 # 80023550 <log>
    80004582:	00004597          	auipc	a1,0x4
    80004586:	0ce58593          	addi	a1,a1,206 # 80008650 <syscalls+0x1f8>
    8000458a:	8526                	mv	a0,s1
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	5ba080e7          	jalr	1466(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004594:	0149a583          	lw	a1,20(s3)
    80004598:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000459a:	0109a783          	lw	a5,16(s3)
    8000459e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045a4:	854a                	mv	a0,s2
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	e8a080e7          	jalr	-374(ra) # 80003430 <bread>
  log.lh.n = lh->n;
    800045ae:	4d34                	lw	a3,88(a0)
    800045b0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045b2:	02d05563          	blez	a3,800045dc <initlog+0x74>
    800045b6:	05c50793          	addi	a5,a0,92
    800045ba:	0001f717          	auipc	a4,0x1f
    800045be:	fc670713          	addi	a4,a4,-58 # 80023580 <log+0x30>
    800045c2:	36fd                	addiw	a3,a3,-1
    800045c4:	1682                	slli	a3,a3,0x20
    800045c6:	9281                	srli	a3,a3,0x20
    800045c8:	068a                	slli	a3,a3,0x2
    800045ca:	06050613          	addi	a2,a0,96
    800045ce:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045d0:	4390                	lw	a2,0(a5)
    800045d2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045d4:	0791                	addi	a5,a5,4
    800045d6:	0711                	addi	a4,a4,4
    800045d8:	fed79ce3          	bne	a5,a3,800045d0 <initlog+0x68>
  brelse(buf);
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	f84080e7          	jalr	-124(ra) # 80003560 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045e4:	4505                	li	a0,1
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	ebe080e7          	jalr	-322(ra) # 800044a4 <install_trans>
  log.lh.n = 0;
    800045ee:	0001f797          	auipc	a5,0x1f
    800045f2:	f807a723          	sw	zero,-114(a5) # 8002357c <log+0x2c>
  write_head(); // clear the log
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	e34080e7          	jalr	-460(ra) # 8000442a <write_head>
}
    800045fe:	70a2                	ld	ra,40(sp)
    80004600:	7402                	ld	s0,32(sp)
    80004602:	64e2                	ld	s1,24(sp)
    80004604:	6942                	ld	s2,16(sp)
    80004606:	69a2                	ld	s3,8(sp)
    80004608:	6145                	addi	sp,sp,48
    8000460a:	8082                	ret

000000008000460c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000460c:	1101                	addi	sp,sp,-32
    8000460e:	ec06                	sd	ra,24(sp)
    80004610:	e822                	sd	s0,16(sp)
    80004612:	e426                	sd	s1,8(sp)
    80004614:	e04a                	sd	s2,0(sp)
    80004616:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004618:	0001f517          	auipc	a0,0x1f
    8000461c:	f3850513          	addi	a0,a0,-200 # 80023550 <log>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5b6080e7          	jalr	1462(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004628:	0001f497          	auipc	s1,0x1f
    8000462c:	f2848493          	addi	s1,s1,-216 # 80023550 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004630:	4979                	li	s2,30
    80004632:	a039                	j	80004640 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004634:	85a6                	mv	a1,s1
    80004636:	8526                	mv	a0,s1
    80004638:	ffffe097          	auipc	ra,0xffffe
    8000463c:	c5a080e7          	jalr	-934(ra) # 80002292 <sleep>
    if(log.committing){
    80004640:	50dc                	lw	a5,36(s1)
    80004642:	fbed                	bnez	a5,80004634 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004644:	509c                	lw	a5,32(s1)
    80004646:	0017871b          	addiw	a4,a5,1
    8000464a:	0007069b          	sext.w	a3,a4
    8000464e:	0027179b          	slliw	a5,a4,0x2
    80004652:	9fb9                	addw	a5,a5,a4
    80004654:	0017979b          	slliw	a5,a5,0x1
    80004658:	54d8                	lw	a4,44(s1)
    8000465a:	9fb9                	addw	a5,a5,a4
    8000465c:	00f95963          	bge	s2,a5,8000466e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004660:	85a6                	mv	a1,s1
    80004662:	8526                	mv	a0,s1
    80004664:	ffffe097          	auipc	ra,0xffffe
    80004668:	c2e080e7          	jalr	-978(ra) # 80002292 <sleep>
    8000466c:	bfd1                	j	80004640 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000466e:	0001f517          	auipc	a0,0x1f
    80004672:	ee250513          	addi	a0,a0,-286 # 80023550 <log>
    80004676:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004680:	60e2                	ld	ra,24(sp)
    80004682:	6442                	ld	s0,16(sp)
    80004684:	64a2                	ld	s1,8(sp)
    80004686:	6902                	ld	s2,0(sp)
    80004688:	6105                	addi	sp,sp,32
    8000468a:	8082                	ret

000000008000468c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000468c:	7139                	addi	sp,sp,-64
    8000468e:	fc06                	sd	ra,56(sp)
    80004690:	f822                	sd	s0,48(sp)
    80004692:	f426                	sd	s1,40(sp)
    80004694:	f04a                	sd	s2,32(sp)
    80004696:	ec4e                	sd	s3,24(sp)
    80004698:	e852                	sd	s4,16(sp)
    8000469a:	e456                	sd	s5,8(sp)
    8000469c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000469e:	0001f497          	auipc	s1,0x1f
    800046a2:	eb248493          	addi	s1,s1,-334 # 80023550 <log>
    800046a6:	8526                	mv	a0,s1
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	52e080e7          	jalr	1326(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800046b0:	509c                	lw	a5,32(s1)
    800046b2:	37fd                	addiw	a5,a5,-1
    800046b4:	0007891b          	sext.w	s2,a5
    800046b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046ba:	50dc                	lw	a5,36(s1)
    800046bc:	e7b9                	bnez	a5,8000470a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046be:	04091e63          	bnez	s2,8000471a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046c2:	0001f497          	auipc	s1,0x1f
    800046c6:	e8e48493          	addi	s1,s1,-370 # 80023550 <log>
    800046ca:	4785                	li	a5,1
    800046cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046d8:	54dc                	lw	a5,44(s1)
    800046da:	06f04763          	bgtz	a5,80004748 <end_op+0xbc>
    acquire(&log.lock);
    800046de:	0001f497          	auipc	s1,0x1f
    800046e2:	e7248493          	addi	s1,s1,-398 # 80023550 <log>
    800046e6:	8526                	mv	a0,s1
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	4ee080e7          	jalr	1262(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800046f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffe097          	auipc	ra,0xffffe
    800046fa:	c00080e7          	jalr	-1024(ra) # 800022f6 <wakeup>
    release(&log.lock);
    800046fe:	8526                	mv	a0,s1
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	58a080e7          	jalr	1418(ra) # 80000c8a <release>
}
    80004708:	a03d                	j	80004736 <end_op+0xaa>
    panic("log.committing");
    8000470a:	00004517          	auipc	a0,0x4
    8000470e:	f4e50513          	addi	a0,a0,-178 # 80008658 <syscalls+0x200>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	e2c080e7          	jalr	-468(ra) # 8000053e <panic>
    wakeup(&log);
    8000471a:	0001f497          	auipc	s1,0x1f
    8000471e:	e3648493          	addi	s1,s1,-458 # 80023550 <log>
    80004722:	8526                	mv	a0,s1
    80004724:	ffffe097          	auipc	ra,0xffffe
    80004728:	bd2080e7          	jalr	-1070(ra) # 800022f6 <wakeup>
  release(&log.lock);
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	55c080e7          	jalr	1372(ra) # 80000c8a <release>
}
    80004736:	70e2                	ld	ra,56(sp)
    80004738:	7442                	ld	s0,48(sp)
    8000473a:	74a2                	ld	s1,40(sp)
    8000473c:	7902                	ld	s2,32(sp)
    8000473e:	69e2                	ld	s3,24(sp)
    80004740:	6a42                	ld	s4,16(sp)
    80004742:	6aa2                	ld	s5,8(sp)
    80004744:	6121                	addi	sp,sp,64
    80004746:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004748:	0001fa97          	auipc	s5,0x1f
    8000474c:	e38a8a93          	addi	s5,s5,-456 # 80023580 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004750:	0001fa17          	auipc	s4,0x1f
    80004754:	e00a0a13          	addi	s4,s4,-512 # 80023550 <log>
    80004758:	018a2583          	lw	a1,24(s4)
    8000475c:	012585bb          	addw	a1,a1,s2
    80004760:	2585                	addiw	a1,a1,1
    80004762:	028a2503          	lw	a0,40(s4)
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	cca080e7          	jalr	-822(ra) # 80003430 <bread>
    8000476e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004770:	000aa583          	lw	a1,0(s5)
    80004774:	028a2503          	lw	a0,40(s4)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	cb8080e7          	jalr	-840(ra) # 80003430 <bread>
    80004780:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004782:	40000613          	li	a2,1024
    80004786:	05850593          	addi	a1,a0,88
    8000478a:	05848513          	addi	a0,s1,88
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	5a0080e7          	jalr	1440(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004796:	8526                	mv	a0,s1
    80004798:	fffff097          	auipc	ra,0xfffff
    8000479c:	d8a080e7          	jalr	-630(ra) # 80003522 <bwrite>
    brelse(from);
    800047a0:	854e                	mv	a0,s3
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	dbe080e7          	jalr	-578(ra) # 80003560 <brelse>
    brelse(to);
    800047aa:	8526                	mv	a0,s1
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	db4080e7          	jalr	-588(ra) # 80003560 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b4:	2905                	addiw	s2,s2,1
    800047b6:	0a91                	addi	s5,s5,4
    800047b8:	02ca2783          	lw	a5,44(s4)
    800047bc:	f8f94ee3          	blt	s2,a5,80004758 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	c6a080e7          	jalr	-918(ra) # 8000442a <write_head>
    install_trans(0); // Now install writes to home locations
    800047c8:	4501                	li	a0,0
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	cda080e7          	jalr	-806(ra) # 800044a4 <install_trans>
    log.lh.n = 0;
    800047d2:	0001f797          	auipc	a5,0x1f
    800047d6:	da07a523          	sw	zero,-598(a5) # 8002357c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047da:	00000097          	auipc	ra,0x0
    800047de:	c50080e7          	jalr	-944(ra) # 8000442a <write_head>
    800047e2:	bdf5                	j	800046de <end_op+0x52>

00000000800047e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047e4:	1101                	addi	sp,sp,-32
    800047e6:	ec06                	sd	ra,24(sp)
    800047e8:	e822                	sd	s0,16(sp)
    800047ea:	e426                	sd	s1,8(sp)
    800047ec:	e04a                	sd	s2,0(sp)
    800047ee:	1000                	addi	s0,sp,32
    800047f0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047f2:	0001f917          	auipc	s2,0x1f
    800047f6:	d5e90913          	addi	s2,s2,-674 # 80023550 <log>
    800047fa:	854a                	mv	a0,s2
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	3da080e7          	jalr	986(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004804:	02c92603          	lw	a2,44(s2)
    80004808:	47f5                	li	a5,29
    8000480a:	06c7c563          	blt	a5,a2,80004874 <log_write+0x90>
    8000480e:	0001f797          	auipc	a5,0x1f
    80004812:	d5e7a783          	lw	a5,-674(a5) # 8002356c <log+0x1c>
    80004816:	37fd                	addiw	a5,a5,-1
    80004818:	04f65e63          	bge	a2,a5,80004874 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000481c:	0001f797          	auipc	a5,0x1f
    80004820:	d547a783          	lw	a5,-684(a5) # 80023570 <log+0x20>
    80004824:	06f05063          	blez	a5,80004884 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004828:	4781                	li	a5,0
    8000482a:	06c05563          	blez	a2,80004894 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000482e:	44cc                	lw	a1,12(s1)
    80004830:	0001f717          	auipc	a4,0x1f
    80004834:	d5070713          	addi	a4,a4,-688 # 80023580 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004838:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000483a:	4314                	lw	a3,0(a4)
    8000483c:	04b68c63          	beq	a3,a1,80004894 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004840:	2785                	addiw	a5,a5,1
    80004842:	0711                	addi	a4,a4,4
    80004844:	fef61be3          	bne	a2,a5,8000483a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004848:	0621                	addi	a2,a2,8
    8000484a:	060a                	slli	a2,a2,0x2
    8000484c:	0001f797          	auipc	a5,0x1f
    80004850:	d0478793          	addi	a5,a5,-764 # 80023550 <log>
    80004854:	963e                	add	a2,a2,a5
    80004856:	44dc                	lw	a5,12(s1)
    80004858:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000485a:	8526                	mv	a0,s1
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	da2080e7          	jalr	-606(ra) # 800035fe <bpin>
    log.lh.n++;
    80004864:	0001f717          	auipc	a4,0x1f
    80004868:	cec70713          	addi	a4,a4,-788 # 80023550 <log>
    8000486c:	575c                	lw	a5,44(a4)
    8000486e:	2785                	addiw	a5,a5,1
    80004870:	d75c                	sw	a5,44(a4)
    80004872:	a835                	j	800048ae <log_write+0xca>
    panic("too big a transaction");
    80004874:	00004517          	auipc	a0,0x4
    80004878:	df450513          	addi	a0,a0,-524 # 80008668 <syscalls+0x210>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004884:	00004517          	auipc	a0,0x4
    80004888:	dfc50513          	addi	a0,a0,-516 # 80008680 <syscalls+0x228>
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	cb2080e7          	jalr	-846(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004894:	00878713          	addi	a4,a5,8
    80004898:	00271693          	slli	a3,a4,0x2
    8000489c:	0001f717          	auipc	a4,0x1f
    800048a0:	cb470713          	addi	a4,a4,-844 # 80023550 <log>
    800048a4:	9736                	add	a4,a4,a3
    800048a6:	44d4                	lw	a3,12(s1)
    800048a8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048aa:	faf608e3          	beq	a2,a5,8000485a <log_write+0x76>
  }
  release(&log.lock);
    800048ae:	0001f517          	auipc	a0,0x1f
    800048b2:	ca250513          	addi	a0,a0,-862 # 80023550 <log>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	3d4080e7          	jalr	980(ra) # 80000c8a <release>
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6902                	ld	s2,0(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048ca:	1101                	addi	sp,sp,-32
    800048cc:	ec06                	sd	ra,24(sp)
    800048ce:	e822                	sd	s0,16(sp)
    800048d0:	e426                	sd	s1,8(sp)
    800048d2:	e04a                	sd	s2,0(sp)
    800048d4:	1000                	addi	s0,sp,32
    800048d6:	84aa                	mv	s1,a0
    800048d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048da:	00004597          	auipc	a1,0x4
    800048de:	dc658593          	addi	a1,a1,-570 # 800086a0 <syscalls+0x248>
    800048e2:	0521                	addi	a0,a0,8
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	262080e7          	jalr	610(ra) # 80000b46 <initlock>
  lk->name = name;
    800048ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048f4:	0204a423          	sw	zero,40(s1)
}
    800048f8:	60e2                	ld	ra,24(sp)
    800048fa:	6442                	ld	s0,16(sp)
    800048fc:	64a2                	ld	s1,8(sp)
    800048fe:	6902                	ld	s2,0(sp)
    80004900:	6105                	addi	sp,sp,32
    80004902:	8082                	ret

0000000080004904 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004904:	1101                	addi	sp,sp,-32
    80004906:	ec06                	sd	ra,24(sp)
    80004908:	e822                	sd	s0,16(sp)
    8000490a:	e426                	sd	s1,8(sp)
    8000490c:	e04a                	sd	s2,0(sp)
    8000490e:	1000                	addi	s0,sp,32
    80004910:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004912:	00850913          	addi	s2,a0,8
    80004916:	854a                	mv	a0,s2
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	2be080e7          	jalr	702(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004920:	409c                	lw	a5,0(s1)
    80004922:	cb89                	beqz	a5,80004934 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004924:	85ca                	mv	a1,s2
    80004926:	8526                	mv	a0,s1
    80004928:	ffffe097          	auipc	ra,0xffffe
    8000492c:	96a080e7          	jalr	-1686(ra) # 80002292 <sleep>
  while (lk->locked) {
    80004930:	409c                	lw	a5,0(s1)
    80004932:	fbed                	bnez	a5,80004924 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004934:	4785                	li	a5,1
    80004936:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004938:	ffffd097          	auipc	ra,0xffffd
    8000493c:	15a080e7          	jalr	346(ra) # 80001a92 <myproc>
    80004940:	591c                	lw	a5,48(a0)
    80004942:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004944:	854a                	mv	a0,s2
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	344080e7          	jalr	836(ra) # 80000c8a <release>
}
    8000494e:	60e2                	ld	ra,24(sp)
    80004950:	6442                	ld	s0,16(sp)
    80004952:	64a2                	ld	s1,8(sp)
    80004954:	6902                	ld	s2,0(sp)
    80004956:	6105                	addi	sp,sp,32
    80004958:	8082                	ret

000000008000495a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000495a:	1101                	addi	sp,sp,-32
    8000495c:	ec06                	sd	ra,24(sp)
    8000495e:	e822                	sd	s0,16(sp)
    80004960:	e426                	sd	s1,8(sp)
    80004962:	e04a                	sd	s2,0(sp)
    80004964:	1000                	addi	s0,sp,32
    80004966:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004968:	00850913          	addi	s2,a0,8
    8000496c:	854a                	mv	a0,s2
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	268080e7          	jalr	616(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004976:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000497a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffe097          	auipc	ra,0xffffe
    80004984:	976080e7          	jalr	-1674(ra) # 800022f6 <wakeup>
  release(&lk->lk);
    80004988:	854a                	mv	a0,s2
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	300080e7          	jalr	768(ra) # 80000c8a <release>
}
    80004992:	60e2                	ld	ra,24(sp)
    80004994:	6442                	ld	s0,16(sp)
    80004996:	64a2                	ld	s1,8(sp)
    80004998:	6902                	ld	s2,0(sp)
    8000499a:	6105                	addi	sp,sp,32
    8000499c:	8082                	ret

000000008000499e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000499e:	7179                	addi	sp,sp,-48
    800049a0:	f406                	sd	ra,40(sp)
    800049a2:	f022                	sd	s0,32(sp)
    800049a4:	ec26                	sd	s1,24(sp)
    800049a6:	e84a                	sd	s2,16(sp)
    800049a8:	e44e                	sd	s3,8(sp)
    800049aa:	1800                	addi	s0,sp,48
    800049ac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049ae:	00850913          	addi	s2,a0,8
    800049b2:	854a                	mv	a0,s2
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	222080e7          	jalr	546(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049bc:	409c                	lw	a5,0(s1)
    800049be:	ef99                	bnez	a5,800049dc <holdingsleep+0x3e>
    800049c0:	4481                	li	s1,0
  release(&lk->lk);
    800049c2:	854a                	mv	a0,s2
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	2c6080e7          	jalr	710(ra) # 80000c8a <release>
  return r;
}
    800049cc:	8526                	mv	a0,s1
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6942                	ld	s2,16(sp)
    800049d6:	69a2                	ld	s3,8(sp)
    800049d8:	6145                	addi	sp,sp,48
    800049da:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049dc:	0284a983          	lw	s3,40(s1)
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	0b2080e7          	jalr	178(ra) # 80001a92 <myproc>
    800049e8:	5904                	lw	s1,48(a0)
    800049ea:	413484b3          	sub	s1,s1,s3
    800049ee:	0014b493          	seqz	s1,s1
    800049f2:	bfc1                	j	800049c2 <holdingsleep+0x24>

00000000800049f4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049f4:	1141                	addi	sp,sp,-16
    800049f6:	e406                	sd	ra,8(sp)
    800049f8:	e022                	sd	s0,0(sp)
    800049fa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049fc:	00004597          	auipc	a1,0x4
    80004a00:	cb458593          	addi	a1,a1,-844 # 800086b0 <syscalls+0x258>
    80004a04:	0001f517          	auipc	a0,0x1f
    80004a08:	c9450513          	addi	a0,a0,-876 # 80023698 <ftable>
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	13a080e7          	jalr	314(ra) # 80000b46 <initlock>
}
    80004a14:	60a2                	ld	ra,8(sp)
    80004a16:	6402                	ld	s0,0(sp)
    80004a18:	0141                	addi	sp,sp,16
    80004a1a:	8082                	ret

0000000080004a1c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a1c:	1101                	addi	sp,sp,-32
    80004a1e:	ec06                	sd	ra,24(sp)
    80004a20:	e822                	sd	s0,16(sp)
    80004a22:	e426                	sd	s1,8(sp)
    80004a24:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a26:	0001f517          	auipc	a0,0x1f
    80004a2a:	c7250513          	addi	a0,a0,-910 # 80023698 <ftable>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	1a8080e7          	jalr	424(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a36:	0001f497          	auipc	s1,0x1f
    80004a3a:	c7a48493          	addi	s1,s1,-902 # 800236b0 <ftable+0x18>
    80004a3e:	00020717          	auipc	a4,0x20
    80004a42:	c1270713          	addi	a4,a4,-1006 # 80024650 <disk>
    if(f->ref == 0){
    80004a46:	40dc                	lw	a5,4(s1)
    80004a48:	cf99                	beqz	a5,80004a66 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a4a:	02848493          	addi	s1,s1,40
    80004a4e:	fee49ce3          	bne	s1,a4,80004a46 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a52:	0001f517          	auipc	a0,0x1f
    80004a56:	c4650513          	addi	a0,a0,-954 # 80023698 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
  return 0;
    80004a62:	4481                	li	s1,0
    80004a64:	a819                	j	80004a7a <filealloc+0x5e>
      f->ref = 1;
    80004a66:	4785                	li	a5,1
    80004a68:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a6a:	0001f517          	auipc	a0,0x1f
    80004a6e:	c2e50513          	addi	a0,a0,-978 # 80023698 <ftable>
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	218080e7          	jalr	536(ra) # 80000c8a <release>
}
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	60e2                	ld	ra,24(sp)
    80004a7e:	6442                	ld	s0,16(sp)
    80004a80:	64a2                	ld	s1,8(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret

0000000080004a86 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a86:	1101                	addi	sp,sp,-32
    80004a88:	ec06                	sd	ra,24(sp)
    80004a8a:	e822                	sd	s0,16(sp)
    80004a8c:	e426                	sd	s1,8(sp)
    80004a8e:	1000                	addi	s0,sp,32
    80004a90:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a92:	0001f517          	auipc	a0,0x1f
    80004a96:	c0650513          	addi	a0,a0,-1018 # 80023698 <ftable>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	13c080e7          	jalr	316(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004aa2:	40dc                	lw	a5,4(s1)
    80004aa4:	02f05263          	blez	a5,80004ac8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004aa8:	2785                	addiw	a5,a5,1
    80004aaa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004aac:	0001f517          	auipc	a0,0x1f
    80004ab0:	bec50513          	addi	a0,a0,-1044 # 80023698 <ftable>
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	1d6080e7          	jalr	470(ra) # 80000c8a <release>
  return f;
}
    80004abc:	8526                	mv	a0,s1
    80004abe:	60e2                	ld	ra,24(sp)
    80004ac0:	6442                	ld	s0,16(sp)
    80004ac2:	64a2                	ld	s1,8(sp)
    80004ac4:	6105                	addi	sp,sp,32
    80004ac6:	8082                	ret
    panic("filedup");
    80004ac8:	00004517          	auipc	a0,0x4
    80004acc:	bf050513          	addi	a0,a0,-1040 # 800086b8 <syscalls+0x260>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	a6e080e7          	jalr	-1426(ra) # 8000053e <panic>

0000000080004ad8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ad8:	7139                	addi	sp,sp,-64
    80004ada:	fc06                	sd	ra,56(sp)
    80004adc:	f822                	sd	s0,48(sp)
    80004ade:	f426                	sd	s1,40(sp)
    80004ae0:	f04a                	sd	s2,32(sp)
    80004ae2:	ec4e                	sd	s3,24(sp)
    80004ae4:	e852                	sd	s4,16(sp)
    80004ae6:	e456                	sd	s5,8(sp)
    80004ae8:	0080                	addi	s0,sp,64
    80004aea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004aec:	0001f517          	auipc	a0,0x1f
    80004af0:	bac50513          	addi	a0,a0,-1108 # 80023698 <ftable>
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	0e2080e7          	jalr	226(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004afc:	40dc                	lw	a5,4(s1)
    80004afe:	06f05163          	blez	a5,80004b60 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b02:	37fd                	addiw	a5,a5,-1
    80004b04:	0007871b          	sext.w	a4,a5
    80004b08:	c0dc                	sw	a5,4(s1)
    80004b0a:	06e04363          	bgtz	a4,80004b70 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b0e:	0004a903          	lw	s2,0(s1)
    80004b12:	0094ca83          	lbu	s5,9(s1)
    80004b16:	0104ba03          	ld	s4,16(s1)
    80004b1a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b1e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b22:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b26:	0001f517          	auipc	a0,0x1f
    80004b2a:	b7250513          	addi	a0,a0,-1166 # 80023698 <ftable>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	15c080e7          	jalr	348(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b36:	4785                	li	a5,1
    80004b38:	04f90d63          	beq	s2,a5,80004b92 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b3c:	3979                	addiw	s2,s2,-2
    80004b3e:	4785                	li	a5,1
    80004b40:	0527e063          	bltu	a5,s2,80004b80 <fileclose+0xa8>
    begin_op();
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	ac8080e7          	jalr	-1336(ra) # 8000460c <begin_op>
    iput(ff.ip);
    80004b4c:	854e                	mv	a0,s3
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	2b6080e7          	jalr	694(ra) # 80003e04 <iput>
    end_op();
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	b36080e7          	jalr	-1226(ra) # 8000468c <end_op>
    80004b5e:	a00d                	j	80004b80 <fileclose+0xa8>
    panic("fileclose");
    80004b60:	00004517          	auipc	a0,0x4
    80004b64:	b6050513          	addi	a0,a0,-1184 # 800086c0 <syscalls+0x268>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	9d6080e7          	jalr	-1578(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b70:	0001f517          	auipc	a0,0x1f
    80004b74:	b2850513          	addi	a0,a0,-1240 # 80023698 <ftable>
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	112080e7          	jalr	274(ra) # 80000c8a <release>
  }
}
    80004b80:	70e2                	ld	ra,56(sp)
    80004b82:	7442                	ld	s0,48(sp)
    80004b84:	74a2                	ld	s1,40(sp)
    80004b86:	7902                	ld	s2,32(sp)
    80004b88:	69e2                	ld	s3,24(sp)
    80004b8a:	6a42                	ld	s4,16(sp)
    80004b8c:	6aa2                	ld	s5,8(sp)
    80004b8e:	6121                	addi	sp,sp,64
    80004b90:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b92:	85d6                	mv	a1,s5
    80004b94:	8552                	mv	a0,s4
    80004b96:	00000097          	auipc	ra,0x0
    80004b9a:	34c080e7          	jalr	844(ra) # 80004ee2 <pipeclose>
    80004b9e:	b7cd                	j	80004b80 <fileclose+0xa8>

0000000080004ba0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ba0:	715d                	addi	sp,sp,-80
    80004ba2:	e486                	sd	ra,72(sp)
    80004ba4:	e0a2                	sd	s0,64(sp)
    80004ba6:	fc26                	sd	s1,56(sp)
    80004ba8:	f84a                	sd	s2,48(sp)
    80004baa:	f44e                	sd	s3,40(sp)
    80004bac:	0880                	addi	s0,sp,80
    80004bae:	84aa                	mv	s1,a0
    80004bb0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	ee0080e7          	jalr	-288(ra) # 80001a92 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bba:	409c                	lw	a5,0(s1)
    80004bbc:	37f9                	addiw	a5,a5,-2
    80004bbe:	4705                	li	a4,1
    80004bc0:	04f76763          	bltu	a4,a5,80004c0e <filestat+0x6e>
    80004bc4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bc6:	6c88                	ld	a0,24(s1)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	082080e7          	jalr	130(ra) # 80003c4a <ilock>
    stati(f->ip, &st);
    80004bd0:	fb840593          	addi	a1,s0,-72
    80004bd4:	6c88                	ld	a0,24(s1)
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	2fe080e7          	jalr	766(ra) # 80003ed4 <stati>
    iunlock(f->ip);
    80004bde:	6c88                	ld	a0,24(s1)
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	12c080e7          	jalr	300(ra) # 80003d0c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004be8:	46e1                	li	a3,24
    80004bea:	fb840613          	addi	a2,s0,-72
    80004bee:	85ce                	mv	a1,s3
    80004bf0:	05893503          	ld	a0,88(s2)
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	a74080e7          	jalr	-1420(ra) # 80001668 <copyout>
    80004bfc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c00:	60a6                	ld	ra,72(sp)
    80004c02:	6406                	ld	s0,64(sp)
    80004c04:	74e2                	ld	s1,56(sp)
    80004c06:	7942                	ld	s2,48(sp)
    80004c08:	79a2                	ld	s3,40(sp)
    80004c0a:	6161                	addi	sp,sp,80
    80004c0c:	8082                	ret
  return -1;
    80004c0e:	557d                	li	a0,-1
    80004c10:	bfc5                	j	80004c00 <filestat+0x60>

0000000080004c12 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c12:	7179                	addi	sp,sp,-48
    80004c14:	f406                	sd	ra,40(sp)
    80004c16:	f022                	sd	s0,32(sp)
    80004c18:	ec26                	sd	s1,24(sp)
    80004c1a:	e84a                	sd	s2,16(sp)
    80004c1c:	e44e                	sd	s3,8(sp)
    80004c1e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c20:	00854783          	lbu	a5,8(a0)
    80004c24:	c3d5                	beqz	a5,80004cc8 <fileread+0xb6>
    80004c26:	84aa                	mv	s1,a0
    80004c28:	89ae                	mv	s3,a1
    80004c2a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c2c:	411c                	lw	a5,0(a0)
    80004c2e:	4705                	li	a4,1
    80004c30:	04e78963          	beq	a5,a4,80004c82 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c34:	470d                	li	a4,3
    80004c36:	04e78d63          	beq	a5,a4,80004c90 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c3a:	4709                	li	a4,2
    80004c3c:	06e79e63          	bne	a5,a4,80004cb8 <fileread+0xa6>
    ilock(f->ip);
    80004c40:	6d08                	ld	a0,24(a0)
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	008080e7          	jalr	8(ra) # 80003c4a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c4a:	874a                	mv	a4,s2
    80004c4c:	5094                	lw	a3,32(s1)
    80004c4e:	864e                	mv	a2,s3
    80004c50:	4585                	li	a1,1
    80004c52:	6c88                	ld	a0,24(s1)
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	2aa080e7          	jalr	682(ra) # 80003efe <readi>
    80004c5c:	892a                	mv	s2,a0
    80004c5e:	00a05563          	blez	a0,80004c68 <fileread+0x56>
      f->off += r;
    80004c62:	509c                	lw	a5,32(s1)
    80004c64:	9fa9                	addw	a5,a5,a0
    80004c66:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c68:	6c88                	ld	a0,24(s1)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	0a2080e7          	jalr	162(ra) # 80003d0c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c72:	854a                	mv	a0,s2
    80004c74:	70a2                	ld	ra,40(sp)
    80004c76:	7402                	ld	s0,32(sp)
    80004c78:	64e2                	ld	s1,24(sp)
    80004c7a:	6942                	ld	s2,16(sp)
    80004c7c:	69a2                	ld	s3,8(sp)
    80004c7e:	6145                	addi	sp,sp,48
    80004c80:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c82:	6908                	ld	a0,16(a0)
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	3c6080e7          	jalr	966(ra) # 8000504a <piperead>
    80004c8c:	892a                	mv	s2,a0
    80004c8e:	b7d5                	j	80004c72 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c90:	02451783          	lh	a5,36(a0)
    80004c94:	03079693          	slli	a3,a5,0x30
    80004c98:	92c1                	srli	a3,a3,0x30
    80004c9a:	4725                	li	a4,9
    80004c9c:	02d76863          	bltu	a4,a3,80004ccc <fileread+0xba>
    80004ca0:	0792                	slli	a5,a5,0x4
    80004ca2:	0001f717          	auipc	a4,0x1f
    80004ca6:	95670713          	addi	a4,a4,-1706 # 800235f8 <devsw>
    80004caa:	97ba                	add	a5,a5,a4
    80004cac:	639c                	ld	a5,0(a5)
    80004cae:	c38d                	beqz	a5,80004cd0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cb0:	4505                	li	a0,1
    80004cb2:	9782                	jalr	a5
    80004cb4:	892a                	mv	s2,a0
    80004cb6:	bf75                	j	80004c72 <fileread+0x60>
    panic("fileread");
    80004cb8:	00004517          	auipc	a0,0x4
    80004cbc:	a1850513          	addi	a0,a0,-1512 # 800086d0 <syscalls+0x278>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	87e080e7          	jalr	-1922(ra) # 8000053e <panic>
    return -1;
    80004cc8:	597d                	li	s2,-1
    80004cca:	b765                	j	80004c72 <fileread+0x60>
      return -1;
    80004ccc:	597d                	li	s2,-1
    80004cce:	b755                	j	80004c72 <fileread+0x60>
    80004cd0:	597d                	li	s2,-1
    80004cd2:	b745                	j	80004c72 <fileread+0x60>

0000000080004cd4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cd4:	715d                	addi	sp,sp,-80
    80004cd6:	e486                	sd	ra,72(sp)
    80004cd8:	e0a2                	sd	s0,64(sp)
    80004cda:	fc26                	sd	s1,56(sp)
    80004cdc:	f84a                	sd	s2,48(sp)
    80004cde:	f44e                	sd	s3,40(sp)
    80004ce0:	f052                	sd	s4,32(sp)
    80004ce2:	ec56                	sd	s5,24(sp)
    80004ce4:	e85a                	sd	s6,16(sp)
    80004ce6:	e45e                	sd	s7,8(sp)
    80004ce8:	e062                	sd	s8,0(sp)
    80004cea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cec:	00954783          	lbu	a5,9(a0)
    80004cf0:	10078663          	beqz	a5,80004dfc <filewrite+0x128>
    80004cf4:	892a                	mv	s2,a0
    80004cf6:	8aae                	mv	s5,a1
    80004cf8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cfa:	411c                	lw	a5,0(a0)
    80004cfc:	4705                	li	a4,1
    80004cfe:	02e78263          	beq	a5,a4,80004d22 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d02:	470d                	li	a4,3
    80004d04:	02e78663          	beq	a5,a4,80004d30 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d08:	4709                	li	a4,2
    80004d0a:	0ee79163          	bne	a5,a4,80004dec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d0e:	0ac05d63          	blez	a2,80004dc8 <filewrite+0xf4>
    int i = 0;
    80004d12:	4981                	li	s3,0
    80004d14:	6b05                	lui	s6,0x1
    80004d16:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d1a:	6b85                	lui	s7,0x1
    80004d1c:	c00b8b9b          	addiw	s7,s7,-1024
    80004d20:	a861                	j	80004db8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d22:	6908                	ld	a0,16(a0)
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	22e080e7          	jalr	558(ra) # 80004f52 <pipewrite>
    80004d2c:	8a2a                	mv	s4,a0
    80004d2e:	a045                	j	80004dce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d30:	02451783          	lh	a5,36(a0)
    80004d34:	03079693          	slli	a3,a5,0x30
    80004d38:	92c1                	srli	a3,a3,0x30
    80004d3a:	4725                	li	a4,9
    80004d3c:	0cd76263          	bltu	a4,a3,80004e00 <filewrite+0x12c>
    80004d40:	0792                	slli	a5,a5,0x4
    80004d42:	0001f717          	auipc	a4,0x1f
    80004d46:	8b670713          	addi	a4,a4,-1866 # 800235f8 <devsw>
    80004d4a:	97ba                	add	a5,a5,a4
    80004d4c:	679c                	ld	a5,8(a5)
    80004d4e:	cbdd                	beqz	a5,80004e04 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d50:	4505                	li	a0,1
    80004d52:	9782                	jalr	a5
    80004d54:	8a2a                	mv	s4,a0
    80004d56:	a8a5                	j	80004dce <filewrite+0xfa>
    80004d58:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	8b0080e7          	jalr	-1872(ra) # 8000460c <begin_op>
      ilock(f->ip);
    80004d64:	01893503          	ld	a0,24(s2)
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	ee2080e7          	jalr	-286(ra) # 80003c4a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d70:	8762                	mv	a4,s8
    80004d72:	02092683          	lw	a3,32(s2)
    80004d76:	01598633          	add	a2,s3,s5
    80004d7a:	4585                	li	a1,1
    80004d7c:	01893503          	ld	a0,24(s2)
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	276080e7          	jalr	630(ra) # 80003ff6 <writei>
    80004d88:	84aa                	mv	s1,a0
    80004d8a:	00a05763          	blez	a0,80004d98 <filewrite+0xc4>
        f->off += r;
    80004d8e:	02092783          	lw	a5,32(s2)
    80004d92:	9fa9                	addw	a5,a5,a0
    80004d94:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d98:	01893503          	ld	a0,24(s2)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	f70080e7          	jalr	-144(ra) # 80003d0c <iunlock>
      end_op();
    80004da4:	00000097          	auipc	ra,0x0
    80004da8:	8e8080e7          	jalr	-1816(ra) # 8000468c <end_op>

      if(r != n1){
    80004dac:	009c1f63          	bne	s8,s1,80004dca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004db0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004db4:	0149db63          	bge	s3,s4,80004dca <filewrite+0xf6>
      int n1 = n - i;
    80004db8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dbc:	84be                	mv	s1,a5
    80004dbe:	2781                	sext.w	a5,a5
    80004dc0:	f8fb5ce3          	bge	s6,a5,80004d58 <filewrite+0x84>
    80004dc4:	84de                	mv	s1,s7
    80004dc6:	bf49                	j	80004d58 <filewrite+0x84>
    int i = 0;
    80004dc8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dca:	013a1f63          	bne	s4,s3,80004de8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dce:	8552                	mv	a0,s4
    80004dd0:	60a6                	ld	ra,72(sp)
    80004dd2:	6406                	ld	s0,64(sp)
    80004dd4:	74e2                	ld	s1,56(sp)
    80004dd6:	7942                	ld	s2,48(sp)
    80004dd8:	79a2                	ld	s3,40(sp)
    80004dda:	7a02                	ld	s4,32(sp)
    80004ddc:	6ae2                	ld	s5,24(sp)
    80004dde:	6b42                	ld	s6,16(sp)
    80004de0:	6ba2                	ld	s7,8(sp)
    80004de2:	6c02                	ld	s8,0(sp)
    80004de4:	6161                	addi	sp,sp,80
    80004de6:	8082                	ret
    ret = (i == n ? n : -1);
    80004de8:	5a7d                	li	s4,-1
    80004dea:	b7d5                	j	80004dce <filewrite+0xfa>
    panic("filewrite");
    80004dec:	00004517          	auipc	a0,0x4
    80004df0:	8f450513          	addi	a0,a0,-1804 # 800086e0 <syscalls+0x288>
    80004df4:	ffffb097          	auipc	ra,0xffffb
    80004df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
    return -1;
    80004dfc:	5a7d                	li	s4,-1
    80004dfe:	bfc1                	j	80004dce <filewrite+0xfa>
      return -1;
    80004e00:	5a7d                	li	s4,-1
    80004e02:	b7f1                	j	80004dce <filewrite+0xfa>
    80004e04:	5a7d                	li	s4,-1
    80004e06:	b7e1                	j	80004dce <filewrite+0xfa>

0000000080004e08 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e08:	7179                	addi	sp,sp,-48
    80004e0a:	f406                	sd	ra,40(sp)
    80004e0c:	f022                	sd	s0,32(sp)
    80004e0e:	ec26                	sd	s1,24(sp)
    80004e10:	e84a                	sd	s2,16(sp)
    80004e12:	e44e                	sd	s3,8(sp)
    80004e14:	e052                	sd	s4,0(sp)
    80004e16:	1800                	addi	s0,sp,48
    80004e18:	84aa                	mv	s1,a0
    80004e1a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e1c:	0005b023          	sd	zero,0(a1)
    80004e20:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e24:	00000097          	auipc	ra,0x0
    80004e28:	bf8080e7          	jalr	-1032(ra) # 80004a1c <filealloc>
    80004e2c:	e088                	sd	a0,0(s1)
    80004e2e:	c551                	beqz	a0,80004eba <pipealloc+0xb2>
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	bec080e7          	jalr	-1044(ra) # 80004a1c <filealloc>
    80004e38:	00aa3023          	sd	a0,0(s4)
    80004e3c:	c92d                	beqz	a0,80004eae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	ca8080e7          	jalr	-856(ra) # 80000ae6 <kalloc>
    80004e46:	892a                	mv	s2,a0
    80004e48:	c125                	beqz	a0,80004ea8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e4a:	4985                	li	s3,1
    80004e4c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e50:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e54:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e58:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e5c:	00004597          	auipc	a1,0x4
    80004e60:	89458593          	addi	a1,a1,-1900 # 800086f0 <syscalls+0x298>
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	ce2080e7          	jalr	-798(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e6c:	609c                	ld	a5,0(s1)
    80004e6e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e72:	609c                	ld	a5,0(s1)
    80004e74:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e78:	609c                	ld	a5,0(s1)
    80004e7a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e7e:	609c                	ld	a5,0(s1)
    80004e80:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e84:	000a3783          	ld	a5,0(s4)
    80004e88:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e8c:	000a3783          	ld	a5,0(s4)
    80004e90:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e94:	000a3783          	ld	a5,0(s4)
    80004e98:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e9c:	000a3783          	ld	a5,0(s4)
    80004ea0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ea4:	4501                	li	a0,0
    80004ea6:	a025                	j	80004ece <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ea8:	6088                	ld	a0,0(s1)
    80004eaa:	e501                	bnez	a0,80004eb2 <pipealloc+0xaa>
    80004eac:	a039                	j	80004eba <pipealloc+0xb2>
    80004eae:	6088                	ld	a0,0(s1)
    80004eb0:	c51d                	beqz	a0,80004ede <pipealloc+0xd6>
    fileclose(*f0);
    80004eb2:	00000097          	auipc	ra,0x0
    80004eb6:	c26080e7          	jalr	-986(ra) # 80004ad8 <fileclose>
  if(*f1)
    80004eba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ebe:	557d                	li	a0,-1
  if(*f1)
    80004ec0:	c799                	beqz	a5,80004ece <pipealloc+0xc6>
    fileclose(*f1);
    80004ec2:	853e                	mv	a0,a5
    80004ec4:	00000097          	auipc	ra,0x0
    80004ec8:	c14080e7          	jalr	-1004(ra) # 80004ad8 <fileclose>
  return -1;
    80004ecc:	557d                	li	a0,-1
}
    80004ece:	70a2                	ld	ra,40(sp)
    80004ed0:	7402                	ld	s0,32(sp)
    80004ed2:	64e2                	ld	s1,24(sp)
    80004ed4:	6942                	ld	s2,16(sp)
    80004ed6:	69a2                	ld	s3,8(sp)
    80004ed8:	6a02                	ld	s4,0(sp)
    80004eda:	6145                	addi	sp,sp,48
    80004edc:	8082                	ret
  return -1;
    80004ede:	557d                	li	a0,-1
    80004ee0:	b7fd                	j	80004ece <pipealloc+0xc6>

0000000080004ee2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ee2:	1101                	addi	sp,sp,-32
    80004ee4:	ec06                	sd	ra,24(sp)
    80004ee6:	e822                	sd	s0,16(sp)
    80004ee8:	e426                	sd	s1,8(sp)
    80004eea:	e04a                	sd	s2,0(sp)
    80004eec:	1000                	addi	s0,sp,32
    80004eee:	84aa                	mv	s1,a0
    80004ef0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	ce4080e7          	jalr	-796(ra) # 80000bd6 <acquire>
  if(writable){
    80004efa:	02090d63          	beqz	s2,80004f34 <pipeclose+0x52>
    pi->writeopen = 0;
    80004efe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f02:	21848513          	addi	a0,s1,536
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	3f0080e7          	jalr	1008(ra) # 800022f6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f0e:	2204b783          	ld	a5,544(s1)
    80004f12:	eb95                	bnez	a5,80004f46 <pipeclose+0x64>
    release(&pi->lock);
    80004f14:	8526                	mv	a0,s1
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	d74080e7          	jalr	-652(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	aca080e7          	jalr	-1334(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004f28:	60e2                	ld	ra,24(sp)
    80004f2a:	6442                	ld	s0,16(sp)
    80004f2c:	64a2                	ld	s1,8(sp)
    80004f2e:	6902                	ld	s2,0(sp)
    80004f30:	6105                	addi	sp,sp,32
    80004f32:	8082                	ret
    pi->readopen = 0;
    80004f34:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f38:	21c48513          	addi	a0,s1,540
    80004f3c:	ffffd097          	auipc	ra,0xffffd
    80004f40:	3ba080e7          	jalr	954(ra) # 800022f6 <wakeup>
    80004f44:	b7e9                	j	80004f0e <pipeclose+0x2c>
    release(&pi->lock);
    80004f46:	8526                	mv	a0,s1
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	d42080e7          	jalr	-702(ra) # 80000c8a <release>
}
    80004f50:	bfe1                	j	80004f28 <pipeclose+0x46>

0000000080004f52 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f52:	711d                	addi	sp,sp,-96
    80004f54:	ec86                	sd	ra,88(sp)
    80004f56:	e8a2                	sd	s0,80(sp)
    80004f58:	e4a6                	sd	s1,72(sp)
    80004f5a:	e0ca                	sd	s2,64(sp)
    80004f5c:	fc4e                	sd	s3,56(sp)
    80004f5e:	f852                	sd	s4,48(sp)
    80004f60:	f456                	sd	s5,40(sp)
    80004f62:	f05a                	sd	s6,32(sp)
    80004f64:	ec5e                	sd	s7,24(sp)
    80004f66:	e862                	sd	s8,16(sp)
    80004f68:	1080                	addi	s0,sp,96
    80004f6a:	84aa                	mv	s1,a0
    80004f6c:	8aae                	mv	s5,a1
    80004f6e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	b22080e7          	jalr	-1246(ra) # 80001a92 <myproc>
    80004f78:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	c5a080e7          	jalr	-934(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f84:	0b405663          	blez	s4,80005030 <pipewrite+0xde>
  int i = 0;
    80004f88:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f8a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f8c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f90:	21c48b93          	addi	s7,s1,540
    80004f94:	a089                	j	80004fd6 <pipewrite+0x84>
      release(&pi->lock);
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	cf2080e7          	jalr	-782(ra) # 80000c8a <release>
      return -1;
    80004fa0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fa2:	854a                	mv	a0,s2
    80004fa4:	60e6                	ld	ra,88(sp)
    80004fa6:	6446                	ld	s0,80(sp)
    80004fa8:	64a6                	ld	s1,72(sp)
    80004faa:	6906                	ld	s2,64(sp)
    80004fac:	79e2                	ld	s3,56(sp)
    80004fae:	7a42                	ld	s4,48(sp)
    80004fb0:	7aa2                	ld	s5,40(sp)
    80004fb2:	7b02                	ld	s6,32(sp)
    80004fb4:	6be2                	ld	s7,24(sp)
    80004fb6:	6c42                	ld	s8,16(sp)
    80004fb8:	6125                	addi	sp,sp,96
    80004fba:	8082                	ret
      wakeup(&pi->nread);
    80004fbc:	8562                	mv	a0,s8
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	338080e7          	jalr	824(ra) # 800022f6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fc6:	85a6                	mv	a1,s1
    80004fc8:	855e                	mv	a0,s7
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	2c8080e7          	jalr	712(ra) # 80002292 <sleep>
  while(i < n){
    80004fd2:	07495063          	bge	s2,s4,80005032 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fd6:	2204a783          	lw	a5,544(s1)
    80004fda:	dfd5                	beqz	a5,80004f96 <pipewrite+0x44>
    80004fdc:	854e                	mv	a0,s3
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	568080e7          	jalr	1384(ra) # 80002546 <killed>
    80004fe6:	f945                	bnez	a0,80004f96 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fe8:	2184a783          	lw	a5,536(s1)
    80004fec:	21c4a703          	lw	a4,540(s1)
    80004ff0:	2007879b          	addiw	a5,a5,512
    80004ff4:	fcf704e3          	beq	a4,a5,80004fbc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ff8:	4685                	li	a3,1
    80004ffa:	01590633          	add	a2,s2,s5
    80004ffe:	faf40593          	addi	a1,s0,-81
    80005002:	0589b503          	ld	a0,88(s3)
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	6ee080e7          	jalr	1774(ra) # 800016f4 <copyin>
    8000500e:	03650263          	beq	a0,s6,80005032 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005012:	21c4a783          	lw	a5,540(s1)
    80005016:	0017871b          	addiw	a4,a5,1
    8000501a:	20e4ae23          	sw	a4,540(s1)
    8000501e:	1ff7f793          	andi	a5,a5,511
    80005022:	97a6                	add	a5,a5,s1
    80005024:	faf44703          	lbu	a4,-81(s0)
    80005028:	00e78c23          	sb	a4,24(a5)
      i++;
    8000502c:	2905                	addiw	s2,s2,1
    8000502e:	b755                	j	80004fd2 <pipewrite+0x80>
  int i = 0;
    80005030:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005032:	21848513          	addi	a0,s1,536
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	2c0080e7          	jalr	704(ra) # 800022f6 <wakeup>
  release(&pi->lock);
    8000503e:	8526                	mv	a0,s1
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	c4a080e7          	jalr	-950(ra) # 80000c8a <release>
  return i;
    80005048:	bfa9                	j	80004fa2 <pipewrite+0x50>

000000008000504a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000504a:	715d                	addi	sp,sp,-80
    8000504c:	e486                	sd	ra,72(sp)
    8000504e:	e0a2                	sd	s0,64(sp)
    80005050:	fc26                	sd	s1,56(sp)
    80005052:	f84a                	sd	s2,48(sp)
    80005054:	f44e                	sd	s3,40(sp)
    80005056:	f052                	sd	s4,32(sp)
    80005058:	ec56                	sd	s5,24(sp)
    8000505a:	e85a                	sd	s6,16(sp)
    8000505c:	0880                	addi	s0,sp,80
    8000505e:	84aa                	mv	s1,a0
    80005060:	892e                	mv	s2,a1
    80005062:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	a2e080e7          	jalr	-1490(ra) # 80001a92 <myproc>
    8000506c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000506e:	8526                	mv	a0,s1
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005078:	2184a703          	lw	a4,536(s1)
    8000507c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005080:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005084:	02f71763          	bne	a4,a5,800050b2 <piperead+0x68>
    80005088:	2244a783          	lw	a5,548(s1)
    8000508c:	c39d                	beqz	a5,800050b2 <piperead+0x68>
    if(killed(pr)){
    8000508e:	8552                	mv	a0,s4
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	4b6080e7          	jalr	1206(ra) # 80002546 <killed>
    80005098:	e941                	bnez	a0,80005128 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000509a:	85a6                	mv	a1,s1
    8000509c:	854e                	mv	a0,s3
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	1f4080e7          	jalr	500(ra) # 80002292 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a6:	2184a703          	lw	a4,536(s1)
    800050aa:	21c4a783          	lw	a5,540(s1)
    800050ae:	fcf70de3          	beq	a4,a5,80005088 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050b4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b6:	05505363          	blez	s5,800050fc <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800050ba:	2184a783          	lw	a5,536(s1)
    800050be:	21c4a703          	lw	a4,540(s1)
    800050c2:	02f70d63          	beq	a4,a5,800050fc <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050c6:	0017871b          	addiw	a4,a5,1
    800050ca:	20e4ac23          	sw	a4,536(s1)
    800050ce:	1ff7f793          	andi	a5,a5,511
    800050d2:	97a6                	add	a5,a5,s1
    800050d4:	0187c783          	lbu	a5,24(a5)
    800050d8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050dc:	4685                	li	a3,1
    800050de:	fbf40613          	addi	a2,s0,-65
    800050e2:	85ca                	mv	a1,s2
    800050e4:	058a3503          	ld	a0,88(s4)
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	580080e7          	jalr	1408(ra) # 80001668 <copyout>
    800050f0:	01650663          	beq	a0,s6,800050fc <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f4:	2985                	addiw	s3,s3,1
    800050f6:	0905                	addi	s2,s2,1
    800050f8:	fd3a91e3          	bne	s5,s3,800050ba <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050fc:	21c48513          	addi	a0,s1,540
    80005100:	ffffd097          	auipc	ra,0xffffd
    80005104:	1f6080e7          	jalr	502(ra) # 800022f6 <wakeup>
  release(&pi->lock);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	b80080e7          	jalr	-1152(ra) # 80000c8a <release>
  return i;
}
    80005112:	854e                	mv	a0,s3
    80005114:	60a6                	ld	ra,72(sp)
    80005116:	6406                	ld	s0,64(sp)
    80005118:	74e2                	ld	s1,56(sp)
    8000511a:	7942                	ld	s2,48(sp)
    8000511c:	79a2                	ld	s3,40(sp)
    8000511e:	7a02                	ld	s4,32(sp)
    80005120:	6ae2                	ld	s5,24(sp)
    80005122:	6b42                	ld	s6,16(sp)
    80005124:	6161                	addi	sp,sp,80
    80005126:	8082                	ret
      release(&pi->lock);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	b60080e7          	jalr	-1184(ra) # 80000c8a <release>
      return -1;
    80005132:	59fd                	li	s3,-1
    80005134:	bff9                	j	80005112 <piperead+0xc8>

0000000080005136 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005136:	1141                	addi	sp,sp,-16
    80005138:	e422                	sd	s0,8(sp)
    8000513a:	0800                	addi	s0,sp,16
    8000513c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000513e:	8905                	andi	a0,a0,1
    80005140:	c111                	beqz	a0,80005144 <flags2perm+0xe>
      perm = PTE_X;
    80005142:	4521                	li	a0,8
    if(flags & 0x2)
    80005144:	8b89                	andi	a5,a5,2
    80005146:	c399                	beqz	a5,8000514c <flags2perm+0x16>
      perm |= PTE_W;
    80005148:	00456513          	ori	a0,a0,4
    return perm;
}
    8000514c:	6422                	ld	s0,8(sp)
    8000514e:	0141                	addi	sp,sp,16
    80005150:	8082                	ret

0000000080005152 <exec>:

int
exec(char *path, char **argv)
{
    80005152:	de010113          	addi	sp,sp,-544
    80005156:	20113c23          	sd	ra,536(sp)
    8000515a:	20813823          	sd	s0,528(sp)
    8000515e:	20913423          	sd	s1,520(sp)
    80005162:	21213023          	sd	s2,512(sp)
    80005166:	ffce                	sd	s3,504(sp)
    80005168:	fbd2                	sd	s4,496(sp)
    8000516a:	f7d6                	sd	s5,488(sp)
    8000516c:	f3da                	sd	s6,480(sp)
    8000516e:	efde                	sd	s7,472(sp)
    80005170:	ebe2                	sd	s8,464(sp)
    80005172:	e7e6                	sd	s9,456(sp)
    80005174:	e3ea                	sd	s10,448(sp)
    80005176:	ff6e                	sd	s11,440(sp)
    80005178:	1400                	addi	s0,sp,544
    8000517a:	892a                	mv	s2,a0
    8000517c:	dea43423          	sd	a0,-536(s0)
    80005180:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	90e080e7          	jalr	-1778(ra) # 80001a92 <myproc>
    8000518c:	84aa                	mv	s1,a0

  begin_op();
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	47e080e7          	jalr	1150(ra) # 8000460c <begin_op>

  if((ip = namei(path)) == 0){
    80005196:	854a                	mv	a0,s2
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	258080e7          	jalr	600(ra) # 800043f0 <namei>
    800051a0:	c93d                	beqz	a0,80005216 <exec+0xc4>
    800051a2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	aa6080e7          	jalr	-1370(ra) # 80003c4a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051ac:	04000713          	li	a4,64
    800051b0:	4681                	li	a3,0
    800051b2:	e5040613          	addi	a2,s0,-432
    800051b6:	4581                	li	a1,0
    800051b8:	8556                	mv	a0,s5
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	d44080e7          	jalr	-700(ra) # 80003efe <readi>
    800051c2:	04000793          	li	a5,64
    800051c6:	00f51a63          	bne	a0,a5,800051da <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051ca:	e5042703          	lw	a4,-432(s0)
    800051ce:	464c47b7          	lui	a5,0x464c4
    800051d2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051d6:	04f70663          	beq	a4,a5,80005222 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051da:	8556                	mv	a0,s5
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	cd0080e7          	jalr	-816(ra) # 80003eac <iunlockput>
    end_op();
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	4a8080e7          	jalr	1192(ra) # 8000468c <end_op>
  }
  return -1;
    800051ec:	557d                	li	a0,-1
}
    800051ee:	21813083          	ld	ra,536(sp)
    800051f2:	21013403          	ld	s0,528(sp)
    800051f6:	20813483          	ld	s1,520(sp)
    800051fa:	20013903          	ld	s2,512(sp)
    800051fe:	79fe                	ld	s3,504(sp)
    80005200:	7a5e                	ld	s4,496(sp)
    80005202:	7abe                	ld	s5,488(sp)
    80005204:	7b1e                	ld	s6,480(sp)
    80005206:	6bfe                	ld	s7,472(sp)
    80005208:	6c5e                	ld	s8,464(sp)
    8000520a:	6cbe                	ld	s9,456(sp)
    8000520c:	6d1e                	ld	s10,448(sp)
    8000520e:	7dfa                	ld	s11,440(sp)
    80005210:	22010113          	addi	sp,sp,544
    80005214:	8082                	ret
    end_op();
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	476080e7          	jalr	1142(ra) # 8000468c <end_op>
    return -1;
    8000521e:	557d                	li	a0,-1
    80005220:	b7f9                	j	800051ee <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005222:	8526                	mv	a0,s1
    80005224:	ffffd097          	auipc	ra,0xffffd
    80005228:	932080e7          	jalr	-1742(ra) # 80001b56 <proc_pagetable>
    8000522c:	8b2a                	mv	s6,a0
    8000522e:	d555                	beqz	a0,800051da <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005230:	e7042783          	lw	a5,-400(s0)
    80005234:	e8845703          	lhu	a4,-376(s0)
    80005238:	c735                	beqz	a4,800052a4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000523a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000523c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005240:	6a05                	lui	s4,0x1
    80005242:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005246:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000524a:	6d85                	lui	s11,0x1
    8000524c:	7d7d                	lui	s10,0xfffff
    8000524e:	a481                	j	8000548e <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005250:	00003517          	auipc	a0,0x3
    80005254:	4a850513          	addi	a0,a0,1192 # 800086f8 <syscalls+0x2a0>
    80005258:	ffffb097          	auipc	ra,0xffffb
    8000525c:	2e6080e7          	jalr	742(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005260:	874a                	mv	a4,s2
    80005262:	009c86bb          	addw	a3,s9,s1
    80005266:	4581                	li	a1,0
    80005268:	8556                	mv	a0,s5
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	c94080e7          	jalr	-876(ra) # 80003efe <readi>
    80005272:	2501                	sext.w	a0,a0
    80005274:	1aa91a63          	bne	s2,a0,80005428 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005278:	009d84bb          	addw	s1,s11,s1
    8000527c:	013d09bb          	addw	s3,s10,s3
    80005280:	1f74f763          	bgeu	s1,s7,8000546e <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005284:	02049593          	slli	a1,s1,0x20
    80005288:	9181                	srli	a1,a1,0x20
    8000528a:	95e2                	add	a1,a1,s8
    8000528c:	855a                	mv	a0,s6
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	dce080e7          	jalr	-562(ra) # 8000105c <walkaddr>
    80005296:	862a                	mv	a2,a0
    if(pa == 0)
    80005298:	dd45                	beqz	a0,80005250 <exec+0xfe>
      n = PGSIZE;
    8000529a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000529c:	fd49f2e3          	bgeu	s3,s4,80005260 <exec+0x10e>
      n = sz - i;
    800052a0:	894e                	mv	s2,s3
    800052a2:	bf7d                	j	80005260 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052a4:	4901                	li	s2,0
  iunlockput(ip);
    800052a6:	8556                	mv	a0,s5
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	c04080e7          	jalr	-1020(ra) # 80003eac <iunlockput>
  end_op();
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	3dc080e7          	jalr	988(ra) # 8000468c <end_op>
  p = myproc();
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	7da080e7          	jalr	2010(ra) # 80001a92 <myproc>
    800052c0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052c2:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800052c6:	6785                	lui	a5,0x1
    800052c8:	17fd                	addi	a5,a5,-1
    800052ca:	993e                	add	s2,s2,a5
    800052cc:	77fd                	lui	a5,0xfffff
    800052ce:	00f977b3          	and	a5,s2,a5
    800052d2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052d6:	4691                	li	a3,4
    800052d8:	6609                	lui	a2,0x2
    800052da:	963e                	add	a2,a2,a5
    800052dc:	85be                	mv	a1,a5
    800052de:	855a                	mv	a0,s6
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	130080e7          	jalr	304(ra) # 80001410 <uvmalloc>
    800052e8:	8c2a                	mv	s8,a0
  ip = 0;
    800052ea:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052ec:	12050e63          	beqz	a0,80005428 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052f0:	75f9                	lui	a1,0xffffe
    800052f2:	95aa                	add	a1,a1,a0
    800052f4:	855a                	mv	a0,s6
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	340080e7          	jalr	832(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800052fe:	7afd                	lui	s5,0xfffff
    80005300:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005302:	df043783          	ld	a5,-528(s0)
    80005306:	6388                	ld	a0,0(a5)
    80005308:	c925                	beqz	a0,80005378 <exec+0x226>
    8000530a:	e9040993          	addi	s3,s0,-368
    8000530e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005312:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005314:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	b38080e7          	jalr	-1224(ra) # 80000e4e <strlen>
    8000531e:	0015079b          	addiw	a5,a0,1
    80005322:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005326:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000532a:	13596663          	bltu	s2,s5,80005456 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000532e:	df043d83          	ld	s11,-528(s0)
    80005332:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005336:	8552                	mv	a0,s4
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	b16080e7          	jalr	-1258(ra) # 80000e4e <strlen>
    80005340:	0015069b          	addiw	a3,a0,1
    80005344:	8652                	mv	a2,s4
    80005346:	85ca                	mv	a1,s2
    80005348:	855a                	mv	a0,s6
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	31e080e7          	jalr	798(ra) # 80001668 <copyout>
    80005352:	10054663          	bltz	a0,8000545e <exec+0x30c>
    ustack[argc] = sp;
    80005356:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000535a:	0485                	addi	s1,s1,1
    8000535c:	008d8793          	addi	a5,s11,8
    80005360:	def43823          	sd	a5,-528(s0)
    80005364:	008db503          	ld	a0,8(s11)
    80005368:	c911                	beqz	a0,8000537c <exec+0x22a>
    if(argc >= MAXARG)
    8000536a:	09a1                	addi	s3,s3,8
    8000536c:	fb3c95e3          	bne	s9,s3,80005316 <exec+0x1c4>
  sz = sz1;
    80005370:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005374:	4a81                	li	s5,0
    80005376:	a84d                	j	80005428 <exec+0x2d6>
  sp = sz;
    80005378:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000537a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000537c:	00349793          	slli	a5,s1,0x3
    80005380:	f9040713          	addi	a4,s0,-112
    80005384:	97ba                	add	a5,a5,a4
    80005386:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffda770>
  sp -= (argc+1) * sizeof(uint64);
    8000538a:	00148693          	addi	a3,s1,1
    8000538e:	068e                	slli	a3,a3,0x3
    80005390:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005394:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005398:	01597663          	bgeu	s2,s5,800053a4 <exec+0x252>
  sz = sz1;
    8000539c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053a0:	4a81                	li	s5,0
    800053a2:	a059                	j	80005428 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053a4:	e9040613          	addi	a2,s0,-368
    800053a8:	85ca                	mv	a1,s2
    800053aa:	855a                	mv	a0,s6
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	2bc080e7          	jalr	700(ra) # 80001668 <copyout>
    800053b4:	0a054963          	bltz	a0,80005466 <exec+0x314>
  p->trapframe->a1 = sp;
    800053b8:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    800053bc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053c0:	de843783          	ld	a5,-536(s0)
    800053c4:	0007c703          	lbu	a4,0(a5)
    800053c8:	cf11                	beqz	a4,800053e4 <exec+0x292>
    800053ca:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053cc:	02f00693          	li	a3,47
    800053d0:	a039                	j	800053de <exec+0x28c>
      last = s+1;
    800053d2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053d6:	0785                	addi	a5,a5,1
    800053d8:	fff7c703          	lbu	a4,-1(a5)
    800053dc:	c701                	beqz	a4,800053e4 <exec+0x292>
    if(*s == '/')
    800053de:	fed71ce3          	bne	a4,a3,800053d6 <exec+0x284>
    800053e2:	bfc5                	j	800053d2 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800053e4:	4641                	li	a2,16
    800053e6:	de843583          	ld	a1,-536(s0)
    800053ea:	160b8513          	addi	a0,s7,352
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	a2e080e7          	jalr	-1490(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800053f6:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800053fa:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800053fe:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005402:	060bb783          	ld	a5,96(s7)
    80005406:	e6843703          	ld	a4,-408(s0)
    8000540a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000540c:	060bb783          	ld	a5,96(s7)
    80005410:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005414:	85ea                	mv	a1,s10
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	7dc080e7          	jalr	2012(ra) # 80001bf2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000541e:	0004851b          	sext.w	a0,s1
    80005422:	b3f1                	j	800051ee <exec+0x9c>
    80005424:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005428:	df843583          	ld	a1,-520(s0)
    8000542c:	855a                	mv	a0,s6
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	7c4080e7          	jalr	1988(ra) # 80001bf2 <proc_freepagetable>
  if(ip){
    80005436:	da0a92e3          	bnez	s5,800051da <exec+0x88>
  return -1;
    8000543a:	557d                	li	a0,-1
    8000543c:	bb4d                	j	800051ee <exec+0x9c>
    8000543e:	df243c23          	sd	s2,-520(s0)
    80005442:	b7dd                	j	80005428 <exec+0x2d6>
    80005444:	df243c23          	sd	s2,-520(s0)
    80005448:	b7c5                	j	80005428 <exec+0x2d6>
    8000544a:	df243c23          	sd	s2,-520(s0)
    8000544e:	bfe9                	j	80005428 <exec+0x2d6>
    80005450:	df243c23          	sd	s2,-520(s0)
    80005454:	bfd1                	j	80005428 <exec+0x2d6>
  sz = sz1;
    80005456:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000545a:	4a81                	li	s5,0
    8000545c:	b7f1                	j	80005428 <exec+0x2d6>
  sz = sz1;
    8000545e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005462:	4a81                	li	s5,0
    80005464:	b7d1                	j	80005428 <exec+0x2d6>
  sz = sz1;
    80005466:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000546a:	4a81                	li	s5,0
    8000546c:	bf75                	j	80005428 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000546e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005472:	e0843783          	ld	a5,-504(s0)
    80005476:	0017869b          	addiw	a3,a5,1
    8000547a:	e0d43423          	sd	a3,-504(s0)
    8000547e:	e0043783          	ld	a5,-512(s0)
    80005482:	0387879b          	addiw	a5,a5,56
    80005486:	e8845703          	lhu	a4,-376(s0)
    8000548a:	e0e6dee3          	bge	a3,a4,800052a6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000548e:	2781                	sext.w	a5,a5
    80005490:	e0f43023          	sd	a5,-512(s0)
    80005494:	03800713          	li	a4,56
    80005498:	86be                	mv	a3,a5
    8000549a:	e1840613          	addi	a2,s0,-488
    8000549e:	4581                	li	a1,0
    800054a0:	8556                	mv	a0,s5
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	a5c080e7          	jalr	-1444(ra) # 80003efe <readi>
    800054aa:	03800793          	li	a5,56
    800054ae:	f6f51be3          	bne	a0,a5,80005424 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800054b2:	e1842783          	lw	a5,-488(s0)
    800054b6:	4705                	li	a4,1
    800054b8:	fae79de3          	bne	a5,a4,80005472 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800054bc:	e4043483          	ld	s1,-448(s0)
    800054c0:	e3843783          	ld	a5,-456(s0)
    800054c4:	f6f4ede3          	bltu	s1,a5,8000543e <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054c8:	e2843783          	ld	a5,-472(s0)
    800054cc:	94be                	add	s1,s1,a5
    800054ce:	f6f4ebe3          	bltu	s1,a5,80005444 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800054d2:	de043703          	ld	a4,-544(s0)
    800054d6:	8ff9                	and	a5,a5,a4
    800054d8:	fbad                	bnez	a5,8000544a <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054da:	e1c42503          	lw	a0,-484(s0)
    800054de:	00000097          	auipc	ra,0x0
    800054e2:	c58080e7          	jalr	-936(ra) # 80005136 <flags2perm>
    800054e6:	86aa                	mv	a3,a0
    800054e8:	8626                	mv	a2,s1
    800054ea:	85ca                	mv	a1,s2
    800054ec:	855a                	mv	a0,s6
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	f22080e7          	jalr	-222(ra) # 80001410 <uvmalloc>
    800054f6:	dea43c23          	sd	a0,-520(s0)
    800054fa:	d939                	beqz	a0,80005450 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054fc:	e2843c03          	ld	s8,-472(s0)
    80005500:	e2042c83          	lw	s9,-480(s0)
    80005504:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005508:	f60b83e3          	beqz	s7,8000546e <exec+0x31c>
    8000550c:	89de                	mv	s3,s7
    8000550e:	4481                	li	s1,0
    80005510:	bb95                	j	80005284 <exec+0x132>

0000000080005512 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005512:	7179                	addi	sp,sp,-48
    80005514:	f406                	sd	ra,40(sp)
    80005516:	f022                	sd	s0,32(sp)
    80005518:	ec26                	sd	s1,24(sp)
    8000551a:	e84a                	sd	s2,16(sp)
    8000551c:	1800                	addi	s0,sp,48
    8000551e:	892e                	mv	s2,a1
    80005520:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005522:	fdc40593          	addi	a1,s0,-36
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	a00080e7          	jalr	-1536(ra) # 80002f26 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000552e:	fdc42703          	lw	a4,-36(s0)
    80005532:	47bd                	li	a5,15
    80005534:	02e7eb63          	bltu	a5,a4,8000556a <argfd+0x58>
    80005538:	ffffc097          	auipc	ra,0xffffc
    8000553c:	55a080e7          	jalr	1370(ra) # 80001a92 <myproc>
    80005540:	fdc42703          	lw	a4,-36(s0)
    80005544:	01a70793          	addi	a5,a4,26
    80005548:	078e                	slli	a5,a5,0x3
    8000554a:	953e                	add	a0,a0,a5
    8000554c:	651c                	ld	a5,8(a0)
    8000554e:	c385                	beqz	a5,8000556e <argfd+0x5c>
    return -1;
  if(pfd)
    80005550:	00090463          	beqz	s2,80005558 <argfd+0x46>
    *pfd = fd;
    80005554:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005558:	4501                	li	a0,0
  if(pf)
    8000555a:	c091                	beqz	s1,8000555e <argfd+0x4c>
    *pf = f;
    8000555c:	e09c                	sd	a5,0(s1)
}
    8000555e:	70a2                	ld	ra,40(sp)
    80005560:	7402                	ld	s0,32(sp)
    80005562:	64e2                	ld	s1,24(sp)
    80005564:	6942                	ld	s2,16(sp)
    80005566:	6145                	addi	sp,sp,48
    80005568:	8082                	ret
    return -1;
    8000556a:	557d                	li	a0,-1
    8000556c:	bfcd                	j	8000555e <argfd+0x4c>
    8000556e:	557d                	li	a0,-1
    80005570:	b7fd                	j	8000555e <argfd+0x4c>

0000000080005572 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005572:	1101                	addi	sp,sp,-32
    80005574:	ec06                	sd	ra,24(sp)
    80005576:	e822                	sd	s0,16(sp)
    80005578:	e426                	sd	s1,8(sp)
    8000557a:	1000                	addi	s0,sp,32
    8000557c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	514080e7          	jalr	1300(ra) # 80001a92 <myproc>
    80005586:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005588:	0d850793          	addi	a5,a0,216
    8000558c:	4501                	li	a0,0
    8000558e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005590:	6398                	ld	a4,0(a5)
    80005592:	cb19                	beqz	a4,800055a8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005594:	2505                	addiw	a0,a0,1
    80005596:	07a1                	addi	a5,a5,8
    80005598:	fed51ce3          	bne	a0,a3,80005590 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000559c:	557d                	li	a0,-1
}
    8000559e:	60e2                	ld	ra,24(sp)
    800055a0:	6442                	ld	s0,16(sp)
    800055a2:	64a2                	ld	s1,8(sp)
    800055a4:	6105                	addi	sp,sp,32
    800055a6:	8082                	ret
      p->ofile[fd] = f;
    800055a8:	01a50793          	addi	a5,a0,26
    800055ac:	078e                	slli	a5,a5,0x3
    800055ae:	963e                	add	a2,a2,a5
    800055b0:	e604                	sd	s1,8(a2)
      return fd;
    800055b2:	b7f5                	j	8000559e <fdalloc+0x2c>

00000000800055b4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055b4:	715d                	addi	sp,sp,-80
    800055b6:	e486                	sd	ra,72(sp)
    800055b8:	e0a2                	sd	s0,64(sp)
    800055ba:	fc26                	sd	s1,56(sp)
    800055bc:	f84a                	sd	s2,48(sp)
    800055be:	f44e                	sd	s3,40(sp)
    800055c0:	f052                	sd	s4,32(sp)
    800055c2:	ec56                	sd	s5,24(sp)
    800055c4:	e85a                	sd	s6,16(sp)
    800055c6:	0880                	addi	s0,sp,80
    800055c8:	8b2e                	mv	s6,a1
    800055ca:	89b2                	mv	s3,a2
    800055cc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055ce:	fb040593          	addi	a1,s0,-80
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	e3c080e7          	jalr	-452(ra) # 8000440e <nameiparent>
    800055da:	84aa                	mv	s1,a0
    800055dc:	14050f63          	beqz	a0,8000573a <create+0x186>
    return 0;

  ilock(dp);
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	66a080e7          	jalr	1642(ra) # 80003c4a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055e8:	4601                	li	a2,0
    800055ea:	fb040593          	addi	a1,s0,-80
    800055ee:	8526                	mv	a0,s1
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	b3e080e7          	jalr	-1218(ra) # 8000412e <dirlookup>
    800055f8:	8aaa                	mv	s5,a0
    800055fa:	c931                	beqz	a0,8000564e <create+0x9a>
    iunlockput(dp);
    800055fc:	8526                	mv	a0,s1
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	8ae080e7          	jalr	-1874(ra) # 80003eac <iunlockput>
    ilock(ip);
    80005606:	8556                	mv	a0,s5
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	642080e7          	jalr	1602(ra) # 80003c4a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005610:	000b059b          	sext.w	a1,s6
    80005614:	4789                	li	a5,2
    80005616:	02f59563          	bne	a1,a5,80005640 <create+0x8c>
    8000561a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffda8b4>
    8000561e:	37f9                	addiw	a5,a5,-2
    80005620:	17c2                	slli	a5,a5,0x30
    80005622:	93c1                	srli	a5,a5,0x30
    80005624:	4705                	li	a4,1
    80005626:	00f76d63          	bltu	a4,a5,80005640 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000562a:	8556                	mv	a0,s5
    8000562c:	60a6                	ld	ra,72(sp)
    8000562e:	6406                	ld	s0,64(sp)
    80005630:	74e2                	ld	s1,56(sp)
    80005632:	7942                	ld	s2,48(sp)
    80005634:	79a2                	ld	s3,40(sp)
    80005636:	7a02                	ld	s4,32(sp)
    80005638:	6ae2                	ld	s5,24(sp)
    8000563a:	6b42                	ld	s6,16(sp)
    8000563c:	6161                	addi	sp,sp,80
    8000563e:	8082                	ret
    iunlockput(ip);
    80005640:	8556                	mv	a0,s5
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	86a080e7          	jalr	-1942(ra) # 80003eac <iunlockput>
    return 0;
    8000564a:	4a81                	li	s5,0
    8000564c:	bff9                	j	8000562a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000564e:	85da                	mv	a1,s6
    80005650:	4088                	lw	a0,0(s1)
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	45c080e7          	jalr	1116(ra) # 80003aae <ialloc>
    8000565a:	8a2a                	mv	s4,a0
    8000565c:	c539                	beqz	a0,800056aa <create+0xf6>
  ilock(ip);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	5ec080e7          	jalr	1516(ra) # 80003c4a <ilock>
  ip->major = major;
    80005666:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000566a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000566e:	4905                	li	s2,1
    80005670:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005674:	8552                	mv	a0,s4
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	50a080e7          	jalr	1290(ra) # 80003b80 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000567e:	000b059b          	sext.w	a1,s6
    80005682:	03258b63          	beq	a1,s2,800056b8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005686:	004a2603          	lw	a2,4(s4)
    8000568a:	fb040593          	addi	a1,s0,-80
    8000568e:	8526                	mv	a0,s1
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	cae080e7          	jalr	-850(ra) # 8000433e <dirlink>
    80005698:	06054f63          	bltz	a0,80005716 <create+0x162>
  iunlockput(dp);
    8000569c:	8526                	mv	a0,s1
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	80e080e7          	jalr	-2034(ra) # 80003eac <iunlockput>
  return ip;
    800056a6:	8ad2                	mv	s5,s4
    800056a8:	b749                	j	8000562a <create+0x76>
    iunlockput(dp);
    800056aa:	8526                	mv	a0,s1
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	800080e7          	jalr	-2048(ra) # 80003eac <iunlockput>
    return 0;
    800056b4:	8ad2                	mv	s5,s4
    800056b6:	bf95                	j	8000562a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056b8:	004a2603          	lw	a2,4(s4)
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	05c58593          	addi	a1,a1,92 # 80008718 <syscalls+0x2c0>
    800056c4:	8552                	mv	a0,s4
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	c78080e7          	jalr	-904(ra) # 8000433e <dirlink>
    800056ce:	04054463          	bltz	a0,80005716 <create+0x162>
    800056d2:	40d0                	lw	a2,4(s1)
    800056d4:	00003597          	auipc	a1,0x3
    800056d8:	04c58593          	addi	a1,a1,76 # 80008720 <syscalls+0x2c8>
    800056dc:	8552                	mv	a0,s4
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	c60080e7          	jalr	-928(ra) # 8000433e <dirlink>
    800056e6:	02054863          	bltz	a0,80005716 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056ea:	004a2603          	lw	a2,4(s4)
    800056ee:	fb040593          	addi	a1,s0,-80
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	c4a080e7          	jalr	-950(ra) # 8000433e <dirlink>
    800056fc:	00054d63          	bltz	a0,80005716 <create+0x162>
    dp->nlink++;  // for ".."
    80005700:	04a4d783          	lhu	a5,74(s1)
    80005704:	2785                	addiw	a5,a5,1
    80005706:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	474080e7          	jalr	1140(ra) # 80003b80 <iupdate>
    80005714:	b761                	j	8000569c <create+0xe8>
  ip->nlink = 0;
    80005716:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000571a:	8552                	mv	a0,s4
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	464080e7          	jalr	1124(ra) # 80003b80 <iupdate>
  iunlockput(ip);
    80005724:	8552                	mv	a0,s4
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	786080e7          	jalr	1926(ra) # 80003eac <iunlockput>
  iunlockput(dp);
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	77c080e7          	jalr	1916(ra) # 80003eac <iunlockput>
  return 0;
    80005738:	bdcd                	j	8000562a <create+0x76>
    return 0;
    8000573a:	8aaa                	mv	s5,a0
    8000573c:	b5fd                	j	8000562a <create+0x76>

000000008000573e <sys_dup>:
{
    8000573e:	7179                	addi	sp,sp,-48
    80005740:	f406                	sd	ra,40(sp)
    80005742:	f022                	sd	s0,32(sp)
    80005744:	ec26                	sd	s1,24(sp)
    80005746:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005748:	fd840613          	addi	a2,s0,-40
    8000574c:	4581                	li	a1,0
    8000574e:	4501                	li	a0,0
    80005750:	00000097          	auipc	ra,0x0
    80005754:	dc2080e7          	jalr	-574(ra) # 80005512 <argfd>
    return -1;
    80005758:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000575a:	02054363          	bltz	a0,80005780 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000575e:	fd843503          	ld	a0,-40(s0)
    80005762:	00000097          	auipc	ra,0x0
    80005766:	e10080e7          	jalr	-496(ra) # 80005572 <fdalloc>
    8000576a:	84aa                	mv	s1,a0
    return -1;
    8000576c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000576e:	00054963          	bltz	a0,80005780 <sys_dup+0x42>
  filedup(f);
    80005772:	fd843503          	ld	a0,-40(s0)
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	310080e7          	jalr	784(ra) # 80004a86 <filedup>
  return fd;
    8000577e:	87a6                	mv	a5,s1
}
    80005780:	853e                	mv	a0,a5
    80005782:	70a2                	ld	ra,40(sp)
    80005784:	7402                	ld	s0,32(sp)
    80005786:	64e2                	ld	s1,24(sp)
    80005788:	6145                	addi	sp,sp,48
    8000578a:	8082                	ret

000000008000578c <sys_read>:
{
    8000578c:	7179                	addi	sp,sp,-48
    8000578e:	f406                	sd	ra,40(sp)
    80005790:	f022                	sd	s0,32(sp)
    80005792:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005794:	fd840593          	addi	a1,s0,-40
    80005798:	4505                	li	a0,1
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	7ac080e7          	jalr	1964(ra) # 80002f46 <argaddr>
  argint(2, &n);
    800057a2:	fe440593          	addi	a1,s0,-28
    800057a6:	4509                	li	a0,2
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	77e080e7          	jalr	1918(ra) # 80002f26 <argint>
  if(argfd(0, 0, &f) < 0)
    800057b0:	fe840613          	addi	a2,s0,-24
    800057b4:	4581                	li	a1,0
    800057b6:	4501                	li	a0,0
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	d5a080e7          	jalr	-678(ra) # 80005512 <argfd>
    800057c0:	87aa                	mv	a5,a0
    return -1;
    800057c2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c4:	0007cc63          	bltz	a5,800057dc <sys_read+0x50>
  return fileread(f, p, n);
    800057c8:	fe442603          	lw	a2,-28(s0)
    800057cc:	fd843583          	ld	a1,-40(s0)
    800057d0:	fe843503          	ld	a0,-24(s0)
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	43e080e7          	jalr	1086(ra) # 80004c12 <fileread>
}
    800057dc:	70a2                	ld	ra,40(sp)
    800057de:	7402                	ld	s0,32(sp)
    800057e0:	6145                	addi	sp,sp,48
    800057e2:	8082                	ret

00000000800057e4 <sys_write>:
{
    800057e4:	7179                	addi	sp,sp,-48
    800057e6:	f406                	sd	ra,40(sp)
    800057e8:	f022                	sd	s0,32(sp)
    800057ea:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057ec:	fd840593          	addi	a1,s0,-40
    800057f0:	4505                	li	a0,1
    800057f2:	ffffd097          	auipc	ra,0xffffd
    800057f6:	754080e7          	jalr	1876(ra) # 80002f46 <argaddr>
  argint(2, &n);
    800057fa:	fe440593          	addi	a1,s0,-28
    800057fe:	4509                	li	a0,2
    80005800:	ffffd097          	auipc	ra,0xffffd
    80005804:	726080e7          	jalr	1830(ra) # 80002f26 <argint>
  if(argfd(0, 0, &f) < 0)
    80005808:	fe840613          	addi	a2,s0,-24
    8000580c:	4581                	li	a1,0
    8000580e:	4501                	li	a0,0
    80005810:	00000097          	auipc	ra,0x0
    80005814:	d02080e7          	jalr	-766(ra) # 80005512 <argfd>
    80005818:	87aa                	mv	a5,a0
    return -1;
    8000581a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000581c:	0007cc63          	bltz	a5,80005834 <sys_write+0x50>
  return filewrite(f, p, n);
    80005820:	fe442603          	lw	a2,-28(s0)
    80005824:	fd843583          	ld	a1,-40(s0)
    80005828:	fe843503          	ld	a0,-24(s0)
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	4a8080e7          	jalr	1192(ra) # 80004cd4 <filewrite>
}
    80005834:	70a2                	ld	ra,40(sp)
    80005836:	7402                	ld	s0,32(sp)
    80005838:	6145                	addi	sp,sp,48
    8000583a:	8082                	ret

000000008000583c <sys_close>:
{
    8000583c:	1101                	addi	sp,sp,-32
    8000583e:	ec06                	sd	ra,24(sp)
    80005840:	e822                	sd	s0,16(sp)
    80005842:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005844:	fe040613          	addi	a2,s0,-32
    80005848:	fec40593          	addi	a1,s0,-20
    8000584c:	4501                	li	a0,0
    8000584e:	00000097          	auipc	ra,0x0
    80005852:	cc4080e7          	jalr	-828(ra) # 80005512 <argfd>
    return -1;
    80005856:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005858:	02054463          	bltz	a0,80005880 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000585c:	ffffc097          	auipc	ra,0xffffc
    80005860:	236080e7          	jalr	566(ra) # 80001a92 <myproc>
    80005864:	fec42783          	lw	a5,-20(s0)
    80005868:	07e9                	addi	a5,a5,26
    8000586a:	078e                	slli	a5,a5,0x3
    8000586c:	97aa                	add	a5,a5,a0
    8000586e:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005872:	fe043503          	ld	a0,-32(s0)
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	262080e7          	jalr	610(ra) # 80004ad8 <fileclose>
  return 0;
    8000587e:	4781                	li	a5,0
}
    80005880:	853e                	mv	a0,a5
    80005882:	60e2                	ld	ra,24(sp)
    80005884:	6442                	ld	s0,16(sp)
    80005886:	6105                	addi	sp,sp,32
    80005888:	8082                	ret

000000008000588a <sys_fstat>:
{
    8000588a:	1101                	addi	sp,sp,-32
    8000588c:	ec06                	sd	ra,24(sp)
    8000588e:	e822                	sd	s0,16(sp)
    80005890:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005892:	fe040593          	addi	a1,s0,-32
    80005896:	4505                	li	a0,1
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	6ae080e7          	jalr	1710(ra) # 80002f46 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058a0:	fe840613          	addi	a2,s0,-24
    800058a4:	4581                	li	a1,0
    800058a6:	4501                	li	a0,0
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	c6a080e7          	jalr	-918(ra) # 80005512 <argfd>
    800058b0:	87aa                	mv	a5,a0
    return -1;
    800058b2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058b4:	0007ca63          	bltz	a5,800058c8 <sys_fstat+0x3e>
  return filestat(f, st);
    800058b8:	fe043583          	ld	a1,-32(s0)
    800058bc:	fe843503          	ld	a0,-24(s0)
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	2e0080e7          	jalr	736(ra) # 80004ba0 <filestat>
}
    800058c8:	60e2                	ld	ra,24(sp)
    800058ca:	6442                	ld	s0,16(sp)
    800058cc:	6105                	addi	sp,sp,32
    800058ce:	8082                	ret

00000000800058d0 <sys_link>:
{
    800058d0:	7169                	addi	sp,sp,-304
    800058d2:	f606                	sd	ra,296(sp)
    800058d4:	f222                	sd	s0,288(sp)
    800058d6:	ee26                	sd	s1,280(sp)
    800058d8:	ea4a                	sd	s2,272(sp)
    800058da:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058dc:	08000613          	li	a2,128
    800058e0:	ed040593          	addi	a1,s0,-304
    800058e4:	4501                	li	a0,0
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	680080e7          	jalr	1664(ra) # 80002f66 <argstr>
    return -1;
    800058ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058f0:	10054e63          	bltz	a0,80005a0c <sys_link+0x13c>
    800058f4:	08000613          	li	a2,128
    800058f8:	f5040593          	addi	a1,s0,-176
    800058fc:	4505                	li	a0,1
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	668080e7          	jalr	1640(ra) # 80002f66 <argstr>
    return -1;
    80005906:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005908:	10054263          	bltz	a0,80005a0c <sys_link+0x13c>
  begin_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	d00080e7          	jalr	-768(ra) # 8000460c <begin_op>
  if((ip = namei(old)) == 0){
    80005914:	ed040513          	addi	a0,s0,-304
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	ad8080e7          	jalr	-1320(ra) # 800043f0 <namei>
    80005920:	84aa                	mv	s1,a0
    80005922:	c551                	beqz	a0,800059ae <sys_link+0xde>
  ilock(ip);
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	326080e7          	jalr	806(ra) # 80003c4a <ilock>
  if(ip->type == T_DIR){
    8000592c:	04449703          	lh	a4,68(s1)
    80005930:	4785                	li	a5,1
    80005932:	08f70463          	beq	a4,a5,800059ba <sys_link+0xea>
  ip->nlink++;
    80005936:	04a4d783          	lhu	a5,74(s1)
    8000593a:	2785                	addiw	a5,a5,1
    8000593c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005940:	8526                	mv	a0,s1
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	23e080e7          	jalr	574(ra) # 80003b80 <iupdate>
  iunlock(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	3c0080e7          	jalr	960(ra) # 80003d0c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005954:	fd040593          	addi	a1,s0,-48
    80005958:	f5040513          	addi	a0,s0,-176
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	ab2080e7          	jalr	-1358(ra) # 8000440e <nameiparent>
    80005964:	892a                	mv	s2,a0
    80005966:	c935                	beqz	a0,800059da <sys_link+0x10a>
  ilock(dp);
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	2e2080e7          	jalr	738(ra) # 80003c4a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005970:	00092703          	lw	a4,0(s2)
    80005974:	409c                	lw	a5,0(s1)
    80005976:	04f71d63          	bne	a4,a5,800059d0 <sys_link+0x100>
    8000597a:	40d0                	lw	a2,4(s1)
    8000597c:	fd040593          	addi	a1,s0,-48
    80005980:	854a                	mv	a0,s2
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	9bc080e7          	jalr	-1604(ra) # 8000433e <dirlink>
    8000598a:	04054363          	bltz	a0,800059d0 <sys_link+0x100>
  iunlockput(dp);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	51c080e7          	jalr	1308(ra) # 80003eac <iunlockput>
  iput(ip);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	46a080e7          	jalr	1130(ra) # 80003e04 <iput>
  end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	cea080e7          	jalr	-790(ra) # 8000468c <end_op>
  return 0;
    800059aa:	4781                	li	a5,0
    800059ac:	a085                	j	80005a0c <sys_link+0x13c>
    end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	cde080e7          	jalr	-802(ra) # 8000468c <end_op>
    return -1;
    800059b6:	57fd                	li	a5,-1
    800059b8:	a891                	j	80005a0c <sys_link+0x13c>
    iunlockput(ip);
    800059ba:	8526                	mv	a0,s1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	4f0080e7          	jalr	1264(ra) # 80003eac <iunlockput>
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	cc8080e7          	jalr	-824(ra) # 8000468c <end_op>
    return -1;
    800059cc:	57fd                	li	a5,-1
    800059ce:	a83d                	j	80005a0c <sys_link+0x13c>
    iunlockput(dp);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	4da080e7          	jalr	1242(ra) # 80003eac <iunlockput>
  ilock(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	26e080e7          	jalr	622(ra) # 80003c4a <ilock>
  ip->nlink--;
    800059e4:	04a4d783          	lhu	a5,74(s1)
    800059e8:	37fd                	addiw	a5,a5,-1
    800059ea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	190080e7          	jalr	400(ra) # 80003b80 <iupdate>
  iunlockput(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	4b2080e7          	jalr	1202(ra) # 80003eac <iunlockput>
  end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	c8a080e7          	jalr	-886(ra) # 8000468c <end_op>
  return -1;
    80005a0a:	57fd                	li	a5,-1
}
    80005a0c:	853e                	mv	a0,a5
    80005a0e:	70b2                	ld	ra,296(sp)
    80005a10:	7412                	ld	s0,288(sp)
    80005a12:	64f2                	ld	s1,280(sp)
    80005a14:	6952                	ld	s2,272(sp)
    80005a16:	6155                	addi	sp,sp,304
    80005a18:	8082                	ret

0000000080005a1a <sys_unlink>:
{
    80005a1a:	7151                	addi	sp,sp,-240
    80005a1c:	f586                	sd	ra,232(sp)
    80005a1e:	f1a2                	sd	s0,224(sp)
    80005a20:	eda6                	sd	s1,216(sp)
    80005a22:	e9ca                	sd	s2,208(sp)
    80005a24:	e5ce                	sd	s3,200(sp)
    80005a26:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a28:	08000613          	li	a2,128
    80005a2c:	f3040593          	addi	a1,s0,-208
    80005a30:	4501                	li	a0,0
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	534080e7          	jalr	1332(ra) # 80002f66 <argstr>
    80005a3a:	18054163          	bltz	a0,80005bbc <sys_unlink+0x1a2>
  begin_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	bce080e7          	jalr	-1074(ra) # 8000460c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a46:	fb040593          	addi	a1,s0,-80
    80005a4a:	f3040513          	addi	a0,s0,-208
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	9c0080e7          	jalr	-1600(ra) # 8000440e <nameiparent>
    80005a56:	84aa                	mv	s1,a0
    80005a58:	c979                	beqz	a0,80005b2e <sys_unlink+0x114>
  ilock(dp);
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	1f0080e7          	jalr	496(ra) # 80003c4a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a62:	00003597          	auipc	a1,0x3
    80005a66:	cb658593          	addi	a1,a1,-842 # 80008718 <syscalls+0x2c0>
    80005a6a:	fb040513          	addi	a0,s0,-80
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	6a6080e7          	jalr	1702(ra) # 80004114 <namecmp>
    80005a76:	14050a63          	beqz	a0,80005bca <sys_unlink+0x1b0>
    80005a7a:	00003597          	auipc	a1,0x3
    80005a7e:	ca658593          	addi	a1,a1,-858 # 80008720 <syscalls+0x2c8>
    80005a82:	fb040513          	addi	a0,s0,-80
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	68e080e7          	jalr	1678(ra) # 80004114 <namecmp>
    80005a8e:	12050e63          	beqz	a0,80005bca <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a92:	f2c40613          	addi	a2,s0,-212
    80005a96:	fb040593          	addi	a1,s0,-80
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	692080e7          	jalr	1682(ra) # 8000412e <dirlookup>
    80005aa4:	892a                	mv	s2,a0
    80005aa6:	12050263          	beqz	a0,80005bca <sys_unlink+0x1b0>
  ilock(ip);
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	1a0080e7          	jalr	416(ra) # 80003c4a <ilock>
  if(ip->nlink < 1)
    80005ab2:	04a91783          	lh	a5,74(s2)
    80005ab6:	08f05263          	blez	a5,80005b3a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005aba:	04491703          	lh	a4,68(s2)
    80005abe:	4785                	li	a5,1
    80005ac0:	08f70563          	beq	a4,a5,80005b4a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ac4:	4641                	li	a2,16
    80005ac6:	4581                	li	a1,0
    80005ac8:	fc040513          	addi	a0,s0,-64
    80005acc:	ffffb097          	auipc	ra,0xffffb
    80005ad0:	206080e7          	jalr	518(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ad4:	4741                	li	a4,16
    80005ad6:	f2c42683          	lw	a3,-212(s0)
    80005ada:	fc040613          	addi	a2,s0,-64
    80005ade:	4581                	li	a1,0
    80005ae0:	8526                	mv	a0,s1
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	514080e7          	jalr	1300(ra) # 80003ff6 <writei>
    80005aea:	47c1                	li	a5,16
    80005aec:	0af51563          	bne	a0,a5,80005b96 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005af0:	04491703          	lh	a4,68(s2)
    80005af4:	4785                	li	a5,1
    80005af6:	0af70863          	beq	a4,a5,80005ba6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	3b0080e7          	jalr	944(ra) # 80003eac <iunlockput>
  ip->nlink--;
    80005b04:	04a95783          	lhu	a5,74(s2)
    80005b08:	37fd                	addiw	a5,a5,-1
    80005b0a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b0e:	854a                	mv	a0,s2
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	070080e7          	jalr	112(ra) # 80003b80 <iupdate>
  iunlockput(ip);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	392080e7          	jalr	914(ra) # 80003eac <iunlockput>
  end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	b6a080e7          	jalr	-1174(ra) # 8000468c <end_op>
  return 0;
    80005b2a:	4501                	li	a0,0
    80005b2c:	a84d                	j	80005bde <sys_unlink+0x1c4>
    end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	b5e080e7          	jalr	-1186(ra) # 8000468c <end_op>
    return -1;
    80005b36:	557d                	li	a0,-1
    80005b38:	a05d                	j	80005bde <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b3a:	00003517          	auipc	a0,0x3
    80005b3e:	bee50513          	addi	a0,a0,-1042 # 80008728 <syscalls+0x2d0>
    80005b42:	ffffb097          	auipc	ra,0xffffb
    80005b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b4a:	04c92703          	lw	a4,76(s2)
    80005b4e:	02000793          	li	a5,32
    80005b52:	f6e7f9e3          	bgeu	a5,a4,80005ac4 <sys_unlink+0xaa>
    80005b56:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b5a:	4741                	li	a4,16
    80005b5c:	86ce                	mv	a3,s3
    80005b5e:	f1840613          	addi	a2,s0,-232
    80005b62:	4581                	li	a1,0
    80005b64:	854a                	mv	a0,s2
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	398080e7          	jalr	920(ra) # 80003efe <readi>
    80005b6e:	47c1                	li	a5,16
    80005b70:	00f51b63          	bne	a0,a5,80005b86 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b74:	f1845783          	lhu	a5,-232(s0)
    80005b78:	e7a1                	bnez	a5,80005bc0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b7a:	29c1                	addiw	s3,s3,16
    80005b7c:	04c92783          	lw	a5,76(s2)
    80005b80:	fcf9ede3          	bltu	s3,a5,80005b5a <sys_unlink+0x140>
    80005b84:	b781                	j	80005ac4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b86:	00003517          	auipc	a0,0x3
    80005b8a:	bba50513          	addi	a0,a0,-1094 # 80008740 <syscalls+0x2e8>
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b96:	00003517          	auipc	a0,0x3
    80005b9a:	bc250513          	addi	a0,a0,-1086 # 80008758 <syscalls+0x300>
    80005b9e:	ffffb097          	auipc	ra,0xffffb
    80005ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    dp->nlink--;
    80005ba6:	04a4d783          	lhu	a5,74(s1)
    80005baa:	37fd                	addiw	a5,a5,-1
    80005bac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	fce080e7          	jalr	-50(ra) # 80003b80 <iupdate>
    80005bba:	b781                	j	80005afa <sys_unlink+0xe0>
    return -1;
    80005bbc:	557d                	li	a0,-1
    80005bbe:	a005                	j	80005bde <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bc0:	854a                	mv	a0,s2
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	2ea080e7          	jalr	746(ra) # 80003eac <iunlockput>
  iunlockput(dp);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	2e0080e7          	jalr	736(ra) # 80003eac <iunlockput>
  end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	ab8080e7          	jalr	-1352(ra) # 8000468c <end_op>
  return -1;
    80005bdc:	557d                	li	a0,-1
}
    80005bde:	70ae                	ld	ra,232(sp)
    80005be0:	740e                	ld	s0,224(sp)
    80005be2:	64ee                	ld	s1,216(sp)
    80005be4:	694e                	ld	s2,208(sp)
    80005be6:	69ae                	ld	s3,200(sp)
    80005be8:	616d                	addi	sp,sp,240
    80005bea:	8082                	ret

0000000080005bec <sys_open>:

uint64
sys_open(void)
{
    80005bec:	7131                	addi	sp,sp,-192
    80005bee:	fd06                	sd	ra,184(sp)
    80005bf0:	f922                	sd	s0,176(sp)
    80005bf2:	f526                	sd	s1,168(sp)
    80005bf4:	f14a                	sd	s2,160(sp)
    80005bf6:	ed4e                	sd	s3,152(sp)
    80005bf8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005bfa:	f4c40593          	addi	a1,s0,-180
    80005bfe:	4505                	li	a0,1
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	326080e7          	jalr	806(ra) # 80002f26 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c08:	08000613          	li	a2,128
    80005c0c:	f5040593          	addi	a1,s0,-176
    80005c10:	4501                	li	a0,0
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	354080e7          	jalr	852(ra) # 80002f66 <argstr>
    80005c1a:	87aa                	mv	a5,a0
    return -1;
    80005c1c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c1e:	0a07c963          	bltz	a5,80005cd0 <sys_open+0xe4>

  begin_op();
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9ea080e7          	jalr	-1558(ra) # 8000460c <begin_op>

  if(omode & O_CREATE){
    80005c2a:	f4c42783          	lw	a5,-180(s0)
    80005c2e:	2007f793          	andi	a5,a5,512
    80005c32:	cfc5                	beqz	a5,80005cea <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c34:	4681                	li	a3,0
    80005c36:	4601                	li	a2,0
    80005c38:	4589                	li	a1,2
    80005c3a:	f5040513          	addi	a0,s0,-176
    80005c3e:	00000097          	auipc	ra,0x0
    80005c42:	976080e7          	jalr	-1674(ra) # 800055b4 <create>
    80005c46:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c48:	c959                	beqz	a0,80005cde <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c4a:	04449703          	lh	a4,68(s1)
    80005c4e:	478d                	li	a5,3
    80005c50:	00f71763          	bne	a4,a5,80005c5e <sys_open+0x72>
    80005c54:	0464d703          	lhu	a4,70(s1)
    80005c58:	47a5                	li	a5,9
    80005c5a:	0ce7ed63          	bltu	a5,a4,80005d34 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	dbe080e7          	jalr	-578(ra) # 80004a1c <filealloc>
    80005c66:	89aa                	mv	s3,a0
    80005c68:	10050363          	beqz	a0,80005d6e <sys_open+0x182>
    80005c6c:	00000097          	auipc	ra,0x0
    80005c70:	906080e7          	jalr	-1786(ra) # 80005572 <fdalloc>
    80005c74:	892a                	mv	s2,a0
    80005c76:	0e054763          	bltz	a0,80005d64 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c7a:	04449703          	lh	a4,68(s1)
    80005c7e:	478d                	li	a5,3
    80005c80:	0cf70563          	beq	a4,a5,80005d4a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c84:	4789                	li	a5,2
    80005c86:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c8a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c8e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c92:	f4c42783          	lw	a5,-180(s0)
    80005c96:	0017c713          	xori	a4,a5,1
    80005c9a:	8b05                	andi	a4,a4,1
    80005c9c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ca0:	0037f713          	andi	a4,a5,3
    80005ca4:	00e03733          	snez	a4,a4
    80005ca8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cac:	4007f793          	andi	a5,a5,1024
    80005cb0:	c791                	beqz	a5,80005cbc <sys_open+0xd0>
    80005cb2:	04449703          	lh	a4,68(s1)
    80005cb6:	4789                	li	a5,2
    80005cb8:	0af70063          	beq	a4,a5,80005d58 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	04e080e7          	jalr	78(ra) # 80003d0c <iunlock>
  end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9c6080e7          	jalr	-1594(ra) # 8000468c <end_op>

  return fd;
    80005cce:	854a                	mv	a0,s2
}
    80005cd0:	70ea                	ld	ra,184(sp)
    80005cd2:	744a                	ld	s0,176(sp)
    80005cd4:	74aa                	ld	s1,168(sp)
    80005cd6:	790a                	ld	s2,160(sp)
    80005cd8:	69ea                	ld	s3,152(sp)
    80005cda:	6129                	addi	sp,sp,192
    80005cdc:	8082                	ret
      end_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	9ae080e7          	jalr	-1618(ra) # 8000468c <end_op>
      return -1;
    80005ce6:	557d                	li	a0,-1
    80005ce8:	b7e5                	j	80005cd0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cea:	f5040513          	addi	a0,s0,-176
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	702080e7          	jalr	1794(ra) # 800043f0 <namei>
    80005cf6:	84aa                	mv	s1,a0
    80005cf8:	c905                	beqz	a0,80005d28 <sys_open+0x13c>
    ilock(ip);
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	f50080e7          	jalr	-176(ra) # 80003c4a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d02:	04449703          	lh	a4,68(s1)
    80005d06:	4785                	li	a5,1
    80005d08:	f4f711e3          	bne	a4,a5,80005c4a <sys_open+0x5e>
    80005d0c:	f4c42783          	lw	a5,-180(s0)
    80005d10:	d7b9                	beqz	a5,80005c5e <sys_open+0x72>
      iunlockput(ip);
    80005d12:	8526                	mv	a0,s1
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	198080e7          	jalr	408(ra) # 80003eac <iunlockput>
      end_op();
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	970080e7          	jalr	-1680(ra) # 8000468c <end_op>
      return -1;
    80005d24:	557d                	li	a0,-1
    80005d26:	b76d                	j	80005cd0 <sys_open+0xe4>
      end_op();
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	964080e7          	jalr	-1692(ra) # 8000468c <end_op>
      return -1;
    80005d30:	557d                	li	a0,-1
    80005d32:	bf79                	j	80005cd0 <sys_open+0xe4>
    iunlockput(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	176080e7          	jalr	374(ra) # 80003eac <iunlockput>
    end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	94e080e7          	jalr	-1714(ra) # 8000468c <end_op>
    return -1;
    80005d46:	557d                	li	a0,-1
    80005d48:	b761                	j	80005cd0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d4a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d4e:	04649783          	lh	a5,70(s1)
    80005d52:	02f99223          	sh	a5,36(s3)
    80005d56:	bf25                	j	80005c8e <sys_open+0xa2>
    itrunc(ip);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	ffe080e7          	jalr	-2(ra) # 80003d58 <itrunc>
    80005d62:	bfa9                	j	80005cbc <sys_open+0xd0>
      fileclose(f);
    80005d64:	854e                	mv	a0,s3
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	d72080e7          	jalr	-654(ra) # 80004ad8 <fileclose>
    iunlockput(ip);
    80005d6e:	8526                	mv	a0,s1
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	13c080e7          	jalr	316(ra) # 80003eac <iunlockput>
    end_op();
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	914080e7          	jalr	-1772(ra) # 8000468c <end_op>
    return -1;
    80005d80:	557d                	li	a0,-1
    80005d82:	b7b9                	j	80005cd0 <sys_open+0xe4>

0000000080005d84 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d84:	7175                	addi	sp,sp,-144
    80005d86:	e506                	sd	ra,136(sp)
    80005d88:	e122                	sd	s0,128(sp)
    80005d8a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	880080e7          	jalr	-1920(ra) # 8000460c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d94:	08000613          	li	a2,128
    80005d98:	f7040593          	addi	a1,s0,-144
    80005d9c:	4501                	li	a0,0
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	1c8080e7          	jalr	456(ra) # 80002f66 <argstr>
    80005da6:	02054963          	bltz	a0,80005dd8 <sys_mkdir+0x54>
    80005daa:	4681                	li	a3,0
    80005dac:	4601                	li	a2,0
    80005dae:	4585                	li	a1,1
    80005db0:	f7040513          	addi	a0,s0,-144
    80005db4:	00000097          	auipc	ra,0x0
    80005db8:	800080e7          	jalr	-2048(ra) # 800055b4 <create>
    80005dbc:	cd11                	beqz	a0,80005dd8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	0ee080e7          	jalr	238(ra) # 80003eac <iunlockput>
  end_op();
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	8c6080e7          	jalr	-1850(ra) # 8000468c <end_op>
  return 0;
    80005dce:	4501                	li	a0,0
}
    80005dd0:	60aa                	ld	ra,136(sp)
    80005dd2:	640a                	ld	s0,128(sp)
    80005dd4:	6149                	addi	sp,sp,144
    80005dd6:	8082                	ret
    end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	8b4080e7          	jalr	-1868(ra) # 8000468c <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	b7fd                	j	80005dd0 <sys_mkdir+0x4c>

0000000080005de4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005de4:	7135                	addi	sp,sp,-160
    80005de6:	ed06                	sd	ra,152(sp)
    80005de8:	e922                	sd	s0,144(sp)
    80005dea:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	820080e7          	jalr	-2016(ra) # 8000460c <begin_op>
  argint(1, &major);
    80005df4:	f6c40593          	addi	a1,s0,-148
    80005df8:	4505                	li	a0,1
    80005dfa:	ffffd097          	auipc	ra,0xffffd
    80005dfe:	12c080e7          	jalr	300(ra) # 80002f26 <argint>
  argint(2, &minor);
    80005e02:	f6840593          	addi	a1,s0,-152
    80005e06:	4509                	li	a0,2
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	11e080e7          	jalr	286(ra) # 80002f26 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e10:	08000613          	li	a2,128
    80005e14:	f7040593          	addi	a1,s0,-144
    80005e18:	4501                	li	a0,0
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	14c080e7          	jalr	332(ra) # 80002f66 <argstr>
    80005e22:	02054b63          	bltz	a0,80005e58 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e26:	f6841683          	lh	a3,-152(s0)
    80005e2a:	f6c41603          	lh	a2,-148(s0)
    80005e2e:	458d                	li	a1,3
    80005e30:	f7040513          	addi	a0,s0,-144
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	780080e7          	jalr	1920(ra) # 800055b4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e3c:	cd11                	beqz	a0,80005e58 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	06e080e7          	jalr	110(ra) # 80003eac <iunlockput>
  end_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	846080e7          	jalr	-1978(ra) # 8000468c <end_op>
  return 0;
    80005e4e:	4501                	li	a0,0
}
    80005e50:	60ea                	ld	ra,152(sp)
    80005e52:	644a                	ld	s0,144(sp)
    80005e54:	610d                	addi	sp,sp,160
    80005e56:	8082                	ret
    end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	834080e7          	jalr	-1996(ra) # 8000468c <end_op>
    return -1;
    80005e60:	557d                	li	a0,-1
    80005e62:	b7fd                	j	80005e50 <sys_mknod+0x6c>

0000000080005e64 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e64:	7135                	addi	sp,sp,-160
    80005e66:	ed06                	sd	ra,152(sp)
    80005e68:	e922                	sd	s0,144(sp)
    80005e6a:	e526                	sd	s1,136(sp)
    80005e6c:	e14a                	sd	s2,128(sp)
    80005e6e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	c22080e7          	jalr	-990(ra) # 80001a92 <myproc>
    80005e78:	892a                	mv	s2,a0
  
  begin_op();
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	792080e7          	jalr	1938(ra) # 8000460c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e82:	08000613          	li	a2,128
    80005e86:	f6040593          	addi	a1,s0,-160
    80005e8a:	4501                	li	a0,0
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	0da080e7          	jalr	218(ra) # 80002f66 <argstr>
    80005e94:	04054b63          	bltz	a0,80005eea <sys_chdir+0x86>
    80005e98:	f6040513          	addi	a0,s0,-160
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	554080e7          	jalr	1364(ra) # 800043f0 <namei>
    80005ea4:	84aa                	mv	s1,a0
    80005ea6:	c131                	beqz	a0,80005eea <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	da2080e7          	jalr	-606(ra) # 80003c4a <ilock>
  if(ip->type != T_DIR){
    80005eb0:	04449703          	lh	a4,68(s1)
    80005eb4:	4785                	li	a5,1
    80005eb6:	04f71063          	bne	a4,a5,80005ef6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005eba:	8526                	mv	a0,s1
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	e50080e7          	jalr	-432(ra) # 80003d0c <iunlock>
  iput(p->cwd);
    80005ec4:	15893503          	ld	a0,344(s2)
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	f3c080e7          	jalr	-196(ra) # 80003e04 <iput>
  end_op();
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	7bc080e7          	jalr	1980(ra) # 8000468c <end_op>
  p->cwd = ip;
    80005ed8:	14993c23          	sd	s1,344(s2)
  return 0;
    80005edc:	4501                	li	a0,0
}
    80005ede:	60ea                	ld	ra,152(sp)
    80005ee0:	644a                	ld	s0,144(sp)
    80005ee2:	64aa                	ld	s1,136(sp)
    80005ee4:	690a                	ld	s2,128(sp)
    80005ee6:	610d                	addi	sp,sp,160
    80005ee8:	8082                	ret
    end_op();
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	7a2080e7          	jalr	1954(ra) # 8000468c <end_op>
    return -1;
    80005ef2:	557d                	li	a0,-1
    80005ef4:	b7ed                	j	80005ede <sys_chdir+0x7a>
    iunlockput(ip);
    80005ef6:	8526                	mv	a0,s1
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	fb4080e7          	jalr	-76(ra) # 80003eac <iunlockput>
    end_op();
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	78c080e7          	jalr	1932(ra) # 8000468c <end_op>
    return -1;
    80005f08:	557d                	li	a0,-1
    80005f0a:	bfd1                	j	80005ede <sys_chdir+0x7a>

0000000080005f0c <sys_exec>:

uint64
sys_exec(void)
{
    80005f0c:	7145                	addi	sp,sp,-464
    80005f0e:	e786                	sd	ra,456(sp)
    80005f10:	e3a2                	sd	s0,448(sp)
    80005f12:	ff26                	sd	s1,440(sp)
    80005f14:	fb4a                	sd	s2,432(sp)
    80005f16:	f74e                	sd	s3,424(sp)
    80005f18:	f352                	sd	s4,416(sp)
    80005f1a:	ef56                	sd	s5,408(sp)
    80005f1c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f1e:	e3840593          	addi	a1,s0,-456
    80005f22:	4505                	li	a0,1
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	022080e7          	jalr	34(ra) # 80002f46 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f2c:	08000613          	li	a2,128
    80005f30:	f4040593          	addi	a1,s0,-192
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	030080e7          	jalr	48(ra) # 80002f66 <argstr>
    80005f3e:	87aa                	mv	a5,a0
    return -1;
    80005f40:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f42:	0c07c263          	bltz	a5,80006006 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f46:	10000613          	li	a2,256
    80005f4a:	4581                	li	a1,0
    80005f4c:	e4040513          	addi	a0,s0,-448
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	d82080e7          	jalr	-638(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f58:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f5c:	89a6                	mv	s3,s1
    80005f5e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f60:	02000a13          	li	s4,32
    80005f64:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f68:	00391793          	slli	a5,s2,0x3
    80005f6c:	e3040593          	addi	a1,s0,-464
    80005f70:	e3843503          	ld	a0,-456(s0)
    80005f74:	953e                	add	a0,a0,a5
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	f12080e7          	jalr	-238(ra) # 80002e88 <fetchaddr>
    80005f7e:	02054a63          	bltz	a0,80005fb2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f82:	e3043783          	ld	a5,-464(s0)
    80005f86:	c3b9                	beqz	a5,80005fcc <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f88:	ffffb097          	auipc	ra,0xffffb
    80005f8c:	b5e080e7          	jalr	-1186(ra) # 80000ae6 <kalloc>
    80005f90:	85aa                	mv	a1,a0
    80005f92:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f96:	cd11                	beqz	a0,80005fb2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f98:	6605                	lui	a2,0x1
    80005f9a:	e3043503          	ld	a0,-464(s0)
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	f3c080e7          	jalr	-196(ra) # 80002eda <fetchstr>
    80005fa6:	00054663          	bltz	a0,80005fb2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005faa:	0905                	addi	s2,s2,1
    80005fac:	09a1                	addi	s3,s3,8
    80005fae:	fb491be3          	bne	s2,s4,80005f64 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb2:	10048913          	addi	s2,s1,256
    80005fb6:	6088                	ld	a0,0(s1)
    80005fb8:	c531                	beqz	a0,80006004 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	a30080e7          	jalr	-1488(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc2:	04a1                	addi	s1,s1,8
    80005fc4:	ff2499e3          	bne	s1,s2,80005fb6 <sys_exec+0xaa>
  return -1;
    80005fc8:	557d                	li	a0,-1
    80005fca:	a835                	j	80006006 <sys_exec+0xfa>
      argv[i] = 0;
    80005fcc:	0a8e                	slli	s5,s5,0x3
    80005fce:	fc040793          	addi	a5,s0,-64
    80005fd2:	9abe                	add	s5,s5,a5
    80005fd4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fd8:	e4040593          	addi	a1,s0,-448
    80005fdc:	f4040513          	addi	a0,s0,-192
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	172080e7          	jalr	370(ra) # 80005152 <exec>
    80005fe8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fea:	10048993          	addi	s3,s1,256
    80005fee:	6088                	ld	a0,0(s1)
    80005ff0:	c901                	beqz	a0,80006000 <sys_exec+0xf4>
    kfree(argv[i]);
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	9f8080e7          	jalr	-1544(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffa:	04a1                	addi	s1,s1,8
    80005ffc:	ff3499e3          	bne	s1,s3,80005fee <sys_exec+0xe2>
  return ret;
    80006000:	854a                	mv	a0,s2
    80006002:	a011                	j	80006006 <sys_exec+0xfa>
  return -1;
    80006004:	557d                	li	a0,-1
}
    80006006:	60be                	ld	ra,456(sp)
    80006008:	641e                	ld	s0,448(sp)
    8000600a:	74fa                	ld	s1,440(sp)
    8000600c:	795a                	ld	s2,432(sp)
    8000600e:	79ba                	ld	s3,424(sp)
    80006010:	7a1a                	ld	s4,416(sp)
    80006012:	6afa                	ld	s5,408(sp)
    80006014:	6179                	addi	sp,sp,464
    80006016:	8082                	ret

0000000080006018 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006018:	7139                	addi	sp,sp,-64
    8000601a:	fc06                	sd	ra,56(sp)
    8000601c:	f822                	sd	s0,48(sp)
    8000601e:	f426                	sd	s1,40(sp)
    80006020:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006022:	ffffc097          	auipc	ra,0xffffc
    80006026:	a70080e7          	jalr	-1424(ra) # 80001a92 <myproc>
    8000602a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000602c:	fd840593          	addi	a1,s0,-40
    80006030:	4501                	li	a0,0
    80006032:	ffffd097          	auipc	ra,0xffffd
    80006036:	f14080e7          	jalr	-236(ra) # 80002f46 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000603a:	fc840593          	addi	a1,s0,-56
    8000603e:	fd040513          	addi	a0,s0,-48
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	dc6080e7          	jalr	-570(ra) # 80004e08 <pipealloc>
    return -1;
    8000604a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000604c:	0c054463          	bltz	a0,80006114 <sys_pipe+0xfc>
  fd0 = -1;
    80006050:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006054:	fd043503          	ld	a0,-48(s0)
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	51a080e7          	jalr	1306(ra) # 80005572 <fdalloc>
    80006060:	fca42223          	sw	a0,-60(s0)
    80006064:	08054b63          	bltz	a0,800060fa <sys_pipe+0xe2>
    80006068:	fc843503          	ld	a0,-56(s0)
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	506080e7          	jalr	1286(ra) # 80005572 <fdalloc>
    80006074:	fca42023          	sw	a0,-64(s0)
    80006078:	06054863          	bltz	a0,800060e8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000607c:	4691                	li	a3,4
    8000607e:	fc440613          	addi	a2,s0,-60
    80006082:	fd843583          	ld	a1,-40(s0)
    80006086:	6ca8                	ld	a0,88(s1)
    80006088:	ffffb097          	auipc	ra,0xffffb
    8000608c:	5e0080e7          	jalr	1504(ra) # 80001668 <copyout>
    80006090:	02054063          	bltz	a0,800060b0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006094:	4691                	li	a3,4
    80006096:	fc040613          	addi	a2,s0,-64
    8000609a:	fd843583          	ld	a1,-40(s0)
    8000609e:	0591                	addi	a1,a1,4
    800060a0:	6ca8                	ld	a0,88(s1)
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	5c6080e7          	jalr	1478(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060aa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060ac:	06055463          	bgez	a0,80006114 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060b0:	fc442783          	lw	a5,-60(s0)
    800060b4:	07e9                	addi	a5,a5,26
    800060b6:	078e                	slli	a5,a5,0x3
    800060b8:	97a6                	add	a5,a5,s1
    800060ba:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800060be:	fc042503          	lw	a0,-64(s0)
    800060c2:	0569                	addi	a0,a0,26
    800060c4:	050e                	slli	a0,a0,0x3
    800060c6:	94aa                	add	s1,s1,a0
    800060c8:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800060cc:	fd043503          	ld	a0,-48(s0)
    800060d0:	fffff097          	auipc	ra,0xfffff
    800060d4:	a08080e7          	jalr	-1528(ra) # 80004ad8 <fileclose>
    fileclose(wf);
    800060d8:	fc843503          	ld	a0,-56(s0)
    800060dc:	fffff097          	auipc	ra,0xfffff
    800060e0:	9fc080e7          	jalr	-1540(ra) # 80004ad8 <fileclose>
    return -1;
    800060e4:	57fd                	li	a5,-1
    800060e6:	a03d                	j	80006114 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060e8:	fc442783          	lw	a5,-60(s0)
    800060ec:	0007c763          	bltz	a5,800060fa <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060f0:	07e9                	addi	a5,a5,26
    800060f2:	078e                	slli	a5,a5,0x3
    800060f4:	94be                	add	s1,s1,a5
    800060f6:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800060fa:	fd043503          	ld	a0,-48(s0)
    800060fe:	fffff097          	auipc	ra,0xfffff
    80006102:	9da080e7          	jalr	-1574(ra) # 80004ad8 <fileclose>
    fileclose(wf);
    80006106:	fc843503          	ld	a0,-56(s0)
    8000610a:	fffff097          	auipc	ra,0xfffff
    8000610e:	9ce080e7          	jalr	-1586(ra) # 80004ad8 <fileclose>
    return -1;
    80006112:	57fd                	li	a5,-1
}
    80006114:	853e                	mv	a0,a5
    80006116:	70e2                	ld	ra,56(sp)
    80006118:	7442                	ld	s0,48(sp)
    8000611a:	74a2                	ld	s1,40(sp)
    8000611c:	6121                	addi	sp,sp,64
    8000611e:	8082                	ret

0000000080006120 <kernelvec>:
    80006120:	7111                	addi	sp,sp,-256
    80006122:	e006                	sd	ra,0(sp)
    80006124:	e40a                	sd	sp,8(sp)
    80006126:	e80e                	sd	gp,16(sp)
    80006128:	ec12                	sd	tp,24(sp)
    8000612a:	f016                	sd	t0,32(sp)
    8000612c:	f41a                	sd	t1,40(sp)
    8000612e:	f81e                	sd	t2,48(sp)
    80006130:	fc22                	sd	s0,56(sp)
    80006132:	e0a6                	sd	s1,64(sp)
    80006134:	e4aa                	sd	a0,72(sp)
    80006136:	e8ae                	sd	a1,80(sp)
    80006138:	ecb2                	sd	a2,88(sp)
    8000613a:	f0b6                	sd	a3,96(sp)
    8000613c:	f4ba                	sd	a4,104(sp)
    8000613e:	f8be                	sd	a5,112(sp)
    80006140:	fcc2                	sd	a6,120(sp)
    80006142:	e146                	sd	a7,128(sp)
    80006144:	e54a                	sd	s2,136(sp)
    80006146:	e94e                	sd	s3,144(sp)
    80006148:	ed52                	sd	s4,152(sp)
    8000614a:	f156                	sd	s5,160(sp)
    8000614c:	f55a                	sd	s6,168(sp)
    8000614e:	f95e                	sd	s7,176(sp)
    80006150:	fd62                	sd	s8,184(sp)
    80006152:	e1e6                	sd	s9,192(sp)
    80006154:	e5ea                	sd	s10,200(sp)
    80006156:	e9ee                	sd	s11,208(sp)
    80006158:	edf2                	sd	t3,216(sp)
    8000615a:	f1f6                	sd	t4,224(sp)
    8000615c:	f5fa                	sd	t5,232(sp)
    8000615e:	f9fe                	sd	t6,240(sp)
    80006160:	bf5fc0ef          	jal	ra,80002d54 <kerneltrap>
    80006164:	6082                	ld	ra,0(sp)
    80006166:	6122                	ld	sp,8(sp)
    80006168:	61c2                	ld	gp,16(sp)
    8000616a:	7282                	ld	t0,32(sp)
    8000616c:	7322                	ld	t1,40(sp)
    8000616e:	73c2                	ld	t2,48(sp)
    80006170:	7462                	ld	s0,56(sp)
    80006172:	6486                	ld	s1,64(sp)
    80006174:	6526                	ld	a0,72(sp)
    80006176:	65c6                	ld	a1,80(sp)
    80006178:	6666                	ld	a2,88(sp)
    8000617a:	7686                	ld	a3,96(sp)
    8000617c:	7726                	ld	a4,104(sp)
    8000617e:	77c6                	ld	a5,112(sp)
    80006180:	7866                	ld	a6,120(sp)
    80006182:	688a                	ld	a7,128(sp)
    80006184:	692a                	ld	s2,136(sp)
    80006186:	69ca                	ld	s3,144(sp)
    80006188:	6a6a                	ld	s4,152(sp)
    8000618a:	7a8a                	ld	s5,160(sp)
    8000618c:	7b2a                	ld	s6,168(sp)
    8000618e:	7bca                	ld	s7,176(sp)
    80006190:	7c6a                	ld	s8,184(sp)
    80006192:	6c8e                	ld	s9,192(sp)
    80006194:	6d2e                	ld	s10,200(sp)
    80006196:	6dce                	ld	s11,208(sp)
    80006198:	6e6e                	ld	t3,216(sp)
    8000619a:	7e8e                	ld	t4,224(sp)
    8000619c:	7f2e                	ld	t5,232(sp)
    8000619e:	7fce                	ld	t6,240(sp)
    800061a0:	6111                	addi	sp,sp,256
    800061a2:	10200073          	sret
    800061a6:	00000013          	nop
    800061aa:	00000013          	nop
    800061ae:	0001                	nop

00000000800061b0 <timervec>:
    800061b0:	34051573          	csrrw	a0,mscratch,a0
    800061b4:	e10c                	sd	a1,0(a0)
    800061b6:	e510                	sd	a2,8(a0)
    800061b8:	e914                	sd	a3,16(a0)
    800061ba:	6d0c                	ld	a1,24(a0)
    800061bc:	7110                	ld	a2,32(a0)
    800061be:	6194                	ld	a3,0(a1)
    800061c0:	96b2                	add	a3,a3,a2
    800061c2:	e194                	sd	a3,0(a1)
    800061c4:	4589                	li	a1,2
    800061c6:	14459073          	csrw	sip,a1
    800061ca:	6914                	ld	a3,16(a0)
    800061cc:	6510                	ld	a2,8(a0)
    800061ce:	610c                	ld	a1,0(a0)
    800061d0:	34051573          	csrrw	a0,mscratch,a0
    800061d4:	30200073          	mret
	...

00000000800061da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061da:	1141                	addi	sp,sp,-16
    800061dc:	e422                	sd	s0,8(sp)
    800061de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061e0:	0c0007b7          	lui	a5,0xc000
    800061e4:	4705                	li	a4,1
    800061e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061e8:	c3d8                	sw	a4,4(a5)
}
    800061ea:	6422                	ld	s0,8(sp)
    800061ec:	0141                	addi	sp,sp,16
    800061ee:	8082                	ret

00000000800061f0 <plicinithart>:

void
plicinithart(void)
{
    800061f0:	1141                	addi	sp,sp,-16
    800061f2:	e406                	sd	ra,8(sp)
    800061f4:	e022                	sd	s0,0(sp)
    800061f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061f8:	ffffc097          	auipc	ra,0xffffc
    800061fc:	86e080e7          	jalr	-1938(ra) # 80001a66 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006200:	0085171b          	slliw	a4,a0,0x8
    80006204:	0c0027b7          	lui	a5,0xc002
    80006208:	97ba                	add	a5,a5,a4
    8000620a:	40200713          	li	a4,1026
    8000620e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006212:	00d5151b          	slliw	a0,a0,0xd
    80006216:	0c2017b7          	lui	a5,0xc201
    8000621a:	953e                	add	a0,a0,a5
    8000621c:	00052023          	sw	zero,0(a0)
}
    80006220:	60a2                	ld	ra,8(sp)
    80006222:	6402                	ld	s0,0(sp)
    80006224:	0141                	addi	sp,sp,16
    80006226:	8082                	ret

0000000080006228 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006228:	1141                	addi	sp,sp,-16
    8000622a:	e406                	sd	ra,8(sp)
    8000622c:	e022                	sd	s0,0(sp)
    8000622e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006230:	ffffc097          	auipc	ra,0xffffc
    80006234:	836080e7          	jalr	-1994(ra) # 80001a66 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006238:	00d5179b          	slliw	a5,a0,0xd
    8000623c:	0c201537          	lui	a0,0xc201
    80006240:	953e                	add	a0,a0,a5
  return irq;
}
    80006242:	4148                	lw	a0,4(a0)
    80006244:	60a2                	ld	ra,8(sp)
    80006246:	6402                	ld	s0,0(sp)
    80006248:	0141                	addi	sp,sp,16
    8000624a:	8082                	ret

000000008000624c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000624c:	1101                	addi	sp,sp,-32
    8000624e:	ec06                	sd	ra,24(sp)
    80006250:	e822                	sd	s0,16(sp)
    80006252:	e426                	sd	s1,8(sp)
    80006254:	1000                	addi	s0,sp,32
    80006256:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006258:	ffffc097          	auipc	ra,0xffffc
    8000625c:	80e080e7          	jalr	-2034(ra) # 80001a66 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006260:	00d5151b          	slliw	a0,a0,0xd
    80006264:	0c2017b7          	lui	a5,0xc201
    80006268:	97aa                	add	a5,a5,a0
    8000626a:	c3c4                	sw	s1,4(a5)
}
    8000626c:	60e2                	ld	ra,24(sp)
    8000626e:	6442                	ld	s0,16(sp)
    80006270:	64a2                	ld	s1,8(sp)
    80006272:	6105                	addi	sp,sp,32
    80006274:	8082                	ret

0000000080006276 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006276:	1141                	addi	sp,sp,-16
    80006278:	e406                	sd	ra,8(sp)
    8000627a:	e022                	sd	s0,0(sp)
    8000627c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000627e:	479d                	li	a5,7
    80006280:	04a7cc63          	blt	a5,a0,800062d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006284:	0001e797          	auipc	a5,0x1e
    80006288:	3cc78793          	addi	a5,a5,972 # 80024650 <disk>
    8000628c:	97aa                	add	a5,a5,a0
    8000628e:	0187c783          	lbu	a5,24(a5)
    80006292:	ebb9                	bnez	a5,800062e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006294:	00451613          	slli	a2,a0,0x4
    80006298:	0001e797          	auipc	a5,0x1e
    8000629c:	3b878793          	addi	a5,a5,952 # 80024650 <disk>
    800062a0:	6394                	ld	a3,0(a5)
    800062a2:	96b2                	add	a3,a3,a2
    800062a4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062a8:	6398                	ld	a4,0(a5)
    800062aa:	9732                	add	a4,a4,a2
    800062ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062b8:	953e                	add	a0,a0,a5
    800062ba:	4785                	li	a5,1
    800062bc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800062c0:	0001e517          	auipc	a0,0x1e
    800062c4:	3a850513          	addi	a0,a0,936 # 80024668 <disk+0x18>
    800062c8:	ffffc097          	auipc	ra,0xffffc
    800062cc:	02e080e7          	jalr	46(ra) # 800022f6 <wakeup>
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	addi	sp,sp,16
    800062d6:	8082                	ret
    panic("free_desc 1");
    800062d8:	00002517          	auipc	a0,0x2
    800062dc:	49050513          	addi	a0,a0,1168 # 80008768 <syscalls+0x310>
    800062e0:	ffffa097          	auipc	ra,0xffffa
    800062e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062e8:	00002517          	auipc	a0,0x2
    800062ec:	49050513          	addi	a0,a0,1168 # 80008778 <syscalls+0x320>
    800062f0:	ffffa097          	auipc	ra,0xffffa
    800062f4:	24e080e7          	jalr	590(ra) # 8000053e <panic>

00000000800062f8 <virtio_disk_init>:
{
    800062f8:	1101                	addi	sp,sp,-32
    800062fa:	ec06                	sd	ra,24(sp)
    800062fc:	e822                	sd	s0,16(sp)
    800062fe:	e426                	sd	s1,8(sp)
    80006300:	e04a                	sd	s2,0(sp)
    80006302:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006304:	00002597          	auipc	a1,0x2
    80006308:	48458593          	addi	a1,a1,1156 # 80008788 <syscalls+0x330>
    8000630c:	0001e517          	auipc	a0,0x1e
    80006310:	46c50513          	addi	a0,a0,1132 # 80024778 <disk+0x128>
    80006314:	ffffb097          	auipc	ra,0xffffb
    80006318:	832080e7          	jalr	-1998(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000631c:	100017b7          	lui	a5,0x10001
    80006320:	4398                	lw	a4,0(a5)
    80006322:	2701                	sext.w	a4,a4
    80006324:	747277b7          	lui	a5,0x74727
    80006328:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000632c:	14f71c63          	bne	a4,a5,80006484 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006330:	100017b7          	lui	a5,0x10001
    80006334:	43dc                	lw	a5,4(a5)
    80006336:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006338:	4709                	li	a4,2
    8000633a:	14e79563          	bne	a5,a4,80006484 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000633e:	100017b7          	lui	a5,0x10001
    80006342:	479c                	lw	a5,8(a5)
    80006344:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006346:	12e79f63          	bne	a5,a4,80006484 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000634a:	100017b7          	lui	a5,0x10001
    8000634e:	47d8                	lw	a4,12(a5)
    80006350:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006352:	554d47b7          	lui	a5,0x554d4
    80006356:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000635a:	12f71563          	bne	a4,a5,80006484 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000635e:	100017b7          	lui	a5,0x10001
    80006362:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006366:	4705                	li	a4,1
    80006368:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636a:	470d                	li	a4,3
    8000636c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000636e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006370:	c7ffe737          	lui	a4,0xc7ffe
    80006374:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9fcf>
    80006378:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000637a:	2701                	sext.w	a4,a4
    8000637c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000637e:	472d                	li	a4,11
    80006380:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006382:	5bbc                	lw	a5,112(a5)
    80006384:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006388:	8ba1                	andi	a5,a5,8
    8000638a:	10078563          	beqz	a5,80006494 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000638e:	100017b7          	lui	a5,0x10001
    80006392:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006396:	43fc                	lw	a5,68(a5)
    80006398:	2781                	sext.w	a5,a5
    8000639a:	10079563          	bnez	a5,800064a4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000639e:	100017b7          	lui	a5,0x10001
    800063a2:	5bdc                	lw	a5,52(a5)
    800063a4:	2781                	sext.w	a5,a5
  if(max == 0)
    800063a6:	10078763          	beqz	a5,800064b4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800063aa:	471d                	li	a4,7
    800063ac:	10f77c63          	bgeu	a4,a5,800064c4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	736080e7          	jalr	1846(ra) # 80000ae6 <kalloc>
    800063b8:	0001e497          	auipc	s1,0x1e
    800063bc:	29848493          	addi	s1,s1,664 # 80024650 <disk>
    800063c0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063c2:	ffffa097          	auipc	ra,0xffffa
    800063c6:	724080e7          	jalr	1828(ra) # 80000ae6 <kalloc>
    800063ca:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	71a080e7          	jalr	1818(ra) # 80000ae6 <kalloc>
    800063d4:	87aa                	mv	a5,a0
    800063d6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063d8:	6088                	ld	a0,0(s1)
    800063da:	cd6d                	beqz	a0,800064d4 <virtio_disk_init+0x1dc>
    800063dc:	0001e717          	auipc	a4,0x1e
    800063e0:	27c73703          	ld	a4,636(a4) # 80024658 <disk+0x8>
    800063e4:	cb65                	beqz	a4,800064d4 <virtio_disk_init+0x1dc>
    800063e6:	c7fd                	beqz	a5,800064d4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800063e8:	6605                	lui	a2,0x1
    800063ea:	4581                	li	a1,0
    800063ec:	ffffb097          	auipc	ra,0xffffb
    800063f0:	8e6080e7          	jalr	-1818(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063f4:	0001e497          	auipc	s1,0x1e
    800063f8:	25c48493          	addi	s1,s1,604 # 80024650 <disk>
    800063fc:	6605                	lui	a2,0x1
    800063fe:	4581                	li	a1,0
    80006400:	6488                	ld	a0,8(s1)
    80006402:	ffffb097          	auipc	ra,0xffffb
    80006406:	8d0080e7          	jalr	-1840(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000640a:	6605                	lui	a2,0x1
    8000640c:	4581                	li	a1,0
    8000640e:	6888                	ld	a0,16(s1)
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	8c2080e7          	jalr	-1854(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	4721                	li	a4,8
    8000641e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006420:	4098                	lw	a4,0(s1)
    80006422:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006426:	40d8                	lw	a4,4(s1)
    80006428:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000642c:	6498                	ld	a4,8(s1)
    8000642e:	0007069b          	sext.w	a3,a4
    80006432:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006436:	9701                	srai	a4,a4,0x20
    80006438:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000643c:	6898                	ld	a4,16(s1)
    8000643e:	0007069b          	sext.w	a3,a4
    80006442:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006446:	9701                	srai	a4,a4,0x20
    80006448:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000644c:	4705                	li	a4,1
    8000644e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006450:	00e48c23          	sb	a4,24(s1)
    80006454:	00e48ca3          	sb	a4,25(s1)
    80006458:	00e48d23          	sb	a4,26(s1)
    8000645c:	00e48da3          	sb	a4,27(s1)
    80006460:	00e48e23          	sb	a4,28(s1)
    80006464:	00e48ea3          	sb	a4,29(s1)
    80006468:	00e48f23          	sb	a4,30(s1)
    8000646c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006470:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006474:	0727a823          	sw	s2,112(a5)
}
    80006478:	60e2                	ld	ra,24(sp)
    8000647a:	6442                	ld	s0,16(sp)
    8000647c:	64a2                	ld	s1,8(sp)
    8000647e:	6902                	ld	s2,0(sp)
    80006480:	6105                	addi	sp,sp,32
    80006482:	8082                	ret
    panic("could not find virtio disk");
    80006484:	00002517          	auipc	a0,0x2
    80006488:	31450513          	addi	a0,a0,788 # 80008798 <syscalls+0x340>
    8000648c:	ffffa097          	auipc	ra,0xffffa
    80006490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006494:	00002517          	auipc	a0,0x2
    80006498:	32450513          	addi	a0,a0,804 # 800087b8 <syscalls+0x360>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800064a4:	00002517          	auipc	a0,0x2
    800064a8:	33450513          	addi	a0,a0,820 # 800087d8 <syscalls+0x380>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064b4:	00002517          	auipc	a0,0x2
    800064b8:	34450513          	addi	a0,a0,836 # 800087f8 <syscalls+0x3a0>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	082080e7          	jalr	130(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	35450513          	addi	a0,a0,852 # 80008818 <syscalls+0x3c0>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	072080e7          	jalr	114(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800064d4:	00002517          	auipc	a0,0x2
    800064d8:	36450513          	addi	a0,a0,868 # 80008838 <syscalls+0x3e0>
    800064dc:	ffffa097          	auipc	ra,0xffffa
    800064e0:	062080e7          	jalr	98(ra) # 8000053e <panic>

00000000800064e4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064e4:	7119                	addi	sp,sp,-128
    800064e6:	fc86                	sd	ra,120(sp)
    800064e8:	f8a2                	sd	s0,112(sp)
    800064ea:	f4a6                	sd	s1,104(sp)
    800064ec:	f0ca                	sd	s2,96(sp)
    800064ee:	ecce                	sd	s3,88(sp)
    800064f0:	e8d2                	sd	s4,80(sp)
    800064f2:	e4d6                	sd	s5,72(sp)
    800064f4:	e0da                	sd	s6,64(sp)
    800064f6:	fc5e                	sd	s7,56(sp)
    800064f8:	f862                	sd	s8,48(sp)
    800064fa:	f466                	sd	s9,40(sp)
    800064fc:	f06a                	sd	s10,32(sp)
    800064fe:	ec6e                	sd	s11,24(sp)
    80006500:	0100                	addi	s0,sp,128
    80006502:	8aaa                	mv	s5,a0
    80006504:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006506:	00c52d03          	lw	s10,12(a0)
    8000650a:	001d1d1b          	slliw	s10,s10,0x1
    8000650e:	1d02                	slli	s10,s10,0x20
    80006510:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006514:	0001e517          	auipc	a0,0x1e
    80006518:	26450513          	addi	a0,a0,612 # 80024778 <disk+0x128>
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	6ba080e7          	jalr	1722(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006524:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006526:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006528:	0001eb97          	auipc	s7,0x1e
    8000652c:	128b8b93          	addi	s7,s7,296 # 80024650 <disk>
  for(int i = 0; i < 3; i++){
    80006530:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006532:	0001ec97          	auipc	s9,0x1e
    80006536:	246c8c93          	addi	s9,s9,582 # 80024778 <disk+0x128>
    8000653a:	a08d                	j	8000659c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000653c:	00fb8733          	add	a4,s7,a5
    80006540:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006544:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006546:	0207c563          	bltz	a5,80006570 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000654a:	2905                	addiw	s2,s2,1
    8000654c:	0611                	addi	a2,a2,4
    8000654e:	05690c63          	beq	s2,s6,800065a6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006552:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006554:	0001e717          	auipc	a4,0x1e
    80006558:	0fc70713          	addi	a4,a4,252 # 80024650 <disk>
    8000655c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000655e:	01874683          	lbu	a3,24(a4)
    80006562:	fee9                	bnez	a3,8000653c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006564:	2785                	addiw	a5,a5,1
    80006566:	0705                	addi	a4,a4,1
    80006568:	fe979be3          	bne	a5,s1,8000655e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000656c:	57fd                	li	a5,-1
    8000656e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006570:	01205d63          	blez	s2,8000658a <virtio_disk_rw+0xa6>
    80006574:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006576:	000a2503          	lw	a0,0(s4)
    8000657a:	00000097          	auipc	ra,0x0
    8000657e:	cfc080e7          	jalr	-772(ra) # 80006276 <free_desc>
      for(int j = 0; j < i; j++)
    80006582:	2d85                	addiw	s11,s11,1
    80006584:	0a11                	addi	s4,s4,4
    80006586:	ffb918e3          	bne	s2,s11,80006576 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000658a:	85e6                	mv	a1,s9
    8000658c:	0001e517          	auipc	a0,0x1e
    80006590:	0dc50513          	addi	a0,a0,220 # 80024668 <disk+0x18>
    80006594:	ffffc097          	auipc	ra,0xffffc
    80006598:	cfe080e7          	jalr	-770(ra) # 80002292 <sleep>
  for(int i = 0; i < 3; i++){
    8000659c:	f8040a13          	addi	s4,s0,-128
{
    800065a0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065a2:	894e                	mv	s2,s3
    800065a4:	b77d                	j	80006552 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065a6:	f8042583          	lw	a1,-128(s0)
    800065aa:	00a58793          	addi	a5,a1,10
    800065ae:	0792                	slli	a5,a5,0x4

  if(write)
    800065b0:	0001e617          	auipc	a2,0x1e
    800065b4:	0a060613          	addi	a2,a2,160 # 80024650 <disk>
    800065b8:	00f60733          	add	a4,a2,a5
    800065bc:	018036b3          	snez	a3,s8
    800065c0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065c2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800065c6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065ca:	f6078693          	addi	a3,a5,-160
    800065ce:	6218                	ld	a4,0(a2)
    800065d0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065d2:	00878513          	addi	a0,a5,8
    800065d6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065d8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065da:	6208                	ld	a0,0(a2)
    800065dc:	96aa                	add	a3,a3,a0
    800065de:	4741                	li	a4,16
    800065e0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065e2:	4705                	li	a4,1
    800065e4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800065e8:	f8442703          	lw	a4,-124(s0)
    800065ec:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065f0:	0712                	slli	a4,a4,0x4
    800065f2:	953a                	add	a0,a0,a4
    800065f4:	058a8693          	addi	a3,s5,88
    800065f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800065fa:	6208                	ld	a0,0(a2)
    800065fc:	972a                	add	a4,a4,a0
    800065fe:	40000693          	li	a3,1024
    80006602:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006604:	001c3c13          	seqz	s8,s8
    80006608:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000660a:	001c6c13          	ori	s8,s8,1
    8000660e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006612:	f8842603          	lw	a2,-120(s0)
    80006616:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000661a:	0001e697          	auipc	a3,0x1e
    8000661e:	03668693          	addi	a3,a3,54 # 80024650 <disk>
    80006622:	00258713          	addi	a4,a1,2
    80006626:	0712                	slli	a4,a4,0x4
    80006628:	9736                	add	a4,a4,a3
    8000662a:	587d                	li	a6,-1
    8000662c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006630:	0612                	slli	a2,a2,0x4
    80006632:	9532                	add	a0,a0,a2
    80006634:	f9078793          	addi	a5,a5,-112
    80006638:	97b6                	add	a5,a5,a3
    8000663a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000663c:	629c                	ld	a5,0(a3)
    8000663e:	97b2                	add	a5,a5,a2
    80006640:	4605                	li	a2,1
    80006642:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006644:	4509                	li	a0,2
    80006646:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000664a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000664e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006652:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006656:	6698                	ld	a4,8(a3)
    80006658:	00275783          	lhu	a5,2(a4)
    8000665c:	8b9d                	andi	a5,a5,7
    8000665e:	0786                	slli	a5,a5,0x1
    80006660:	97ba                	add	a5,a5,a4
    80006662:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006666:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000666a:	6698                	ld	a4,8(a3)
    8000666c:	00275783          	lhu	a5,2(a4)
    80006670:	2785                	addiw	a5,a5,1
    80006672:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006676:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000667a:	100017b7          	lui	a5,0x10001
    8000667e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006682:	004aa783          	lw	a5,4(s5)
    80006686:	02c79163          	bne	a5,a2,800066a8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000668a:	0001e917          	auipc	s2,0x1e
    8000668e:	0ee90913          	addi	s2,s2,238 # 80024778 <disk+0x128>
  while(b->disk == 1) {
    80006692:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006694:	85ca                	mv	a1,s2
    80006696:	8556                	mv	a0,s5
    80006698:	ffffc097          	auipc	ra,0xffffc
    8000669c:	bfa080e7          	jalr	-1030(ra) # 80002292 <sleep>
  while(b->disk == 1) {
    800066a0:	004aa783          	lw	a5,4(s5)
    800066a4:	fe9788e3          	beq	a5,s1,80006694 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066a8:	f8042903          	lw	s2,-128(s0)
    800066ac:	00290793          	addi	a5,s2,2
    800066b0:	00479713          	slli	a4,a5,0x4
    800066b4:	0001e797          	auipc	a5,0x1e
    800066b8:	f9c78793          	addi	a5,a5,-100 # 80024650 <disk>
    800066bc:	97ba                	add	a5,a5,a4
    800066be:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066c2:	0001e997          	auipc	s3,0x1e
    800066c6:	f8e98993          	addi	s3,s3,-114 # 80024650 <disk>
    800066ca:	00491713          	slli	a4,s2,0x4
    800066ce:	0009b783          	ld	a5,0(s3)
    800066d2:	97ba                	add	a5,a5,a4
    800066d4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066d8:	854a                	mv	a0,s2
    800066da:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066de:	00000097          	auipc	ra,0x0
    800066e2:	b98080e7          	jalr	-1128(ra) # 80006276 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066e6:	8885                	andi	s1,s1,1
    800066e8:	f0ed                	bnez	s1,800066ca <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066ea:	0001e517          	auipc	a0,0x1e
    800066ee:	08e50513          	addi	a0,a0,142 # 80024778 <disk+0x128>
    800066f2:	ffffa097          	auipc	ra,0xffffa
    800066f6:	598080e7          	jalr	1432(ra) # 80000c8a <release>
}
    800066fa:	70e6                	ld	ra,120(sp)
    800066fc:	7446                	ld	s0,112(sp)
    800066fe:	74a6                	ld	s1,104(sp)
    80006700:	7906                	ld	s2,96(sp)
    80006702:	69e6                	ld	s3,88(sp)
    80006704:	6a46                	ld	s4,80(sp)
    80006706:	6aa6                	ld	s5,72(sp)
    80006708:	6b06                	ld	s6,64(sp)
    8000670a:	7be2                	ld	s7,56(sp)
    8000670c:	7c42                	ld	s8,48(sp)
    8000670e:	7ca2                	ld	s9,40(sp)
    80006710:	7d02                	ld	s10,32(sp)
    80006712:	6de2                	ld	s11,24(sp)
    80006714:	6109                	addi	sp,sp,128
    80006716:	8082                	ret

0000000080006718 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006718:	1101                	addi	sp,sp,-32
    8000671a:	ec06                	sd	ra,24(sp)
    8000671c:	e822                	sd	s0,16(sp)
    8000671e:	e426                	sd	s1,8(sp)
    80006720:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006722:	0001e497          	auipc	s1,0x1e
    80006726:	f2e48493          	addi	s1,s1,-210 # 80024650 <disk>
    8000672a:	0001e517          	auipc	a0,0x1e
    8000672e:	04e50513          	addi	a0,a0,78 # 80024778 <disk+0x128>
    80006732:	ffffa097          	auipc	ra,0xffffa
    80006736:	4a4080e7          	jalr	1188(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000673a:	10001737          	lui	a4,0x10001
    8000673e:	533c                	lw	a5,96(a4)
    80006740:	8b8d                	andi	a5,a5,3
    80006742:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006744:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006748:	689c                	ld	a5,16(s1)
    8000674a:	0204d703          	lhu	a4,32(s1)
    8000674e:	0027d783          	lhu	a5,2(a5)
    80006752:	04f70863          	beq	a4,a5,800067a2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006756:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000675a:	6898                	ld	a4,16(s1)
    8000675c:	0204d783          	lhu	a5,32(s1)
    80006760:	8b9d                	andi	a5,a5,7
    80006762:	078e                	slli	a5,a5,0x3
    80006764:	97ba                	add	a5,a5,a4
    80006766:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006768:	00278713          	addi	a4,a5,2
    8000676c:	0712                	slli	a4,a4,0x4
    8000676e:	9726                	add	a4,a4,s1
    80006770:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006774:	e721                	bnez	a4,800067bc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006776:	0789                	addi	a5,a5,2
    80006778:	0792                	slli	a5,a5,0x4
    8000677a:	97a6                	add	a5,a5,s1
    8000677c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000677e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006782:	ffffc097          	auipc	ra,0xffffc
    80006786:	b74080e7          	jalr	-1164(ra) # 800022f6 <wakeup>

    disk.used_idx += 1;
    8000678a:	0204d783          	lhu	a5,32(s1)
    8000678e:	2785                	addiw	a5,a5,1
    80006790:	17c2                	slli	a5,a5,0x30
    80006792:	93c1                	srli	a5,a5,0x30
    80006794:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006798:	6898                	ld	a4,16(s1)
    8000679a:	00275703          	lhu	a4,2(a4)
    8000679e:	faf71ce3          	bne	a4,a5,80006756 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067a2:	0001e517          	auipc	a0,0x1e
    800067a6:	fd650513          	addi	a0,a0,-42 # 80024778 <disk+0x128>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	4e0080e7          	jalr	1248(ra) # 80000c8a <release>
}
    800067b2:	60e2                	ld	ra,24(sp)
    800067b4:	6442                	ld	s0,16(sp)
    800067b6:	64a2                	ld	s1,8(sp)
    800067b8:	6105                	addi	sp,sp,32
    800067ba:	8082                	ret
      panic("virtio_disk_intr status");
    800067bc:	00002517          	auipc	a0,0x2
    800067c0:	09450513          	addi	a0,a0,148 # 80008850 <syscalls+0x3f8>
    800067c4:	ffffa097          	auipc	ra,0xffffa
    800067c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>
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
