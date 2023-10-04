
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
    80000068:	f5c78793          	addi	a5,a5,-164 # 80005fc0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbe9f>
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
    80000130:	422080e7          	jalr	1058(ra) # 8000254e <either_copyin>
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
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1d0080e7          	jalr	464(ra) # 80002398 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f0e080e7          	jalr	-242(ra) # 800020e4 <sleep>
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
    80000216:	2e6080e7          	jalr	742(ra) # 800024f8 <either_copyout>
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
    800002f6:	2b2080e7          	jalr	690(ra) # 800025a4 <procdump>
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
    8000044a:	d02080e7          	jalr	-766(ra) # 80002148 <wakeup>
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
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	35078793          	addi	a5,a5,848 # 800217c8 <devsw>
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
    80000896:	8b6080e7          	jalr	-1866(ra) # 80002148 <wakeup>
    
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
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7c8080e7          	jalr	1992(ra) # 800020e4 <sleep>
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
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	f6278793          	addi	a5,a5,-158 # 80022960 <end>
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
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	e9250513          	addi	a0,a0,-366 # 80022960 <end>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
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
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
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
    80000ec2:	9d0080e7          	jalr	-1584(ra) # 8000288e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	13a080e7          	jalr	314(ra) # 80006000 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	008080e7          	jalr	8(ra) # 80001ed6 <scheduler>
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
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	930080e7          	jalr	-1744(ra) # 80002866 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	950080e7          	jalr	-1712(ra) # 8000288e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	0a4080e7          	jalr	164(ra) # 80005fea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	0b2080e7          	jalr	178(ra) # 80006000 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	252080e7          	jalr	594(ra) # 800031a8 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8f6080e7          	jalr	-1802(ra) # 80003854 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	894080e7          	jalr	-1900(ra) # 800047fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	19a080e7          	jalr	410(ra) # 80006108 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d42080e7          	jalr	-702(ra) # 80001cb8 <userinit>
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
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
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

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	d1aa0a13          	addi	s4,s4,-742 # 80017580 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19848493          	addi	s1,s1,408
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	26850513          	addi	a0,a0,616 # 80010b50 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	26850513          	addi	a0,a0,616 # 80010b68 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	67048493          	addi	s1,s1,1648 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	c4e98993          	addi	s3,s3,-946 # 80017580 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	19848493          	addi	s1,s1,408
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1e450513          	addi	a0,a0,484 # 80010b80 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	18c70713          	addi	a4,a4,396 # 80010b50 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	ea0080e7          	jalr	-352(ra) # 800028a6 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	db4080e7          	jalr	-588(ra) # 800037d4 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	11a90913          	addi	s2,s2,282 # 80010b50 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	06093683          	ld	a3,96(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	7128                	ld	a0,96(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001b7a:	6ca8                	ld	a0,88(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  p=kalloc();
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	f24080e7          	jalr	-220(ra) # 80000ae6 <kalloc>
    80001bca:	84aa                	mv	s1,a0
  if(p==0){
    80001bcc:	c55d                	beqz	a0,80001c7a <allocproc+0xc4>
  p->current_ticks=0;
    80001bce:	06052623          	sw	zero,108(a0)
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd2:	0000f497          	auipc	s1,0xf
    80001bd6:	3ae48493          	addi	s1,s1,942 # 80010f80 <proc>
    80001bda:	00016917          	auipc	s2,0x16
    80001bde:	9a690913          	addi	s2,s2,-1626 # 80017580 <tickslock>
    acquire(&p->lock);
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	ff2080e7          	jalr	-14(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bec:	4c9c                	lw	a5,24(s1)
    80001bee:	cf81                	beqz	a5,80001c06 <allocproc+0x50>
      release(&p->lock);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	098080e7          	jalr	152(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bfa:	19848493          	addi	s1,s1,408
    80001bfe:	ff2492e3          	bne	s1,s2,80001be2 <allocproc+0x2c>
  return 0;
    80001c02:	4481                	li	s1,0
    80001c04:	a89d                	j	80001c7a <allocproc+0xc4>
  p->pid = allocpid();
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	e24080e7          	jalr	-476(ra) # 80001a2a <allocpid>
    80001c0e:	d888                	sw	a0,48(s1)
  p->readcount=0;    //Initializing read count to 0
    80001c10:	0204aa23          	sw	zero,52(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
p->creation_time=ticks;
    80001c18:	00007797          	auipc	a5,0x7
    80001c1c:	cc87a783          	lw	a5,-824(a5) # 800088e0 <ticks>
    80001c20:	18f4a423          	sw	a5,392(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	ec2080e7          	jalr	-318(ra) # 80000ae6 <kalloc>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	f0a8                	sd	a0,96(s1)
    80001c30:	cd21                	beqz	a0,80001c88 <allocproc+0xd2>
  p->pagetable = proc_pagetable(p);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e3c080e7          	jalr	-452(ra) # 80001a70 <proc_pagetable>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001c40:	c125                	beqz	a0,80001ca0 <allocproc+0xea>
  memset(&p->context, 0, sizeof(p->context));
    80001c42:	07000613          	li	a2,112
    80001c46:	4581                	li	a1,0
    80001c48:	08048513          	addi	a0,s1,128
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	086080e7          	jalr	134(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	d9078793          	addi	a5,a5,-624 # 800019e4 <forkret>
    80001c5c:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	60bc                	ld	a5,64(s1)
    80001c60:	6705                	lui	a4,0x1
    80001c62:	97ba                	add	a5,a5,a4
    80001c64:	e4dc                	sd	a5,136(s1)
  p->rtime = 0;
    80001c66:	1804a623          	sw	zero,396(s1)
  p->etime = 0;
    80001c6a:	1804aa23          	sw	zero,404(s1)
  p->ctime = ticks;
    80001c6e:	00007797          	auipc	a5,0x7
    80001c72:	c727a783          	lw	a5,-910(a5) # 800088e0 <ticks>
    80001c76:	18f4a823          	sw	a5,400(s1)
}
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret
    freeproc(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	ed4080e7          	jalr	-300(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	ff6080e7          	jalr	-10(ra) # 80000c8a <release>
    return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	bff1                	j	80001c7a <allocproc+0xc4>
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ebc080e7          	jalr	-324(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fde080e7          	jalr	-34(ra) # 80000c8a <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7d1                	j	80001c7a <allocproc+0xc4>

0000000080001cb8 <userinit>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	ef4080e7          	jalr	-268(ra) # 80001bb6 <allocproc>
    80001cca:	84aa                	mv	s1,a0
  initproc = p;
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	c0a7b623          	sd	a0,-1012(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd4:	03400613          	li	a2,52
    80001cd8:	00007597          	auipc	a1,0x7
    80001cdc:	b9858593          	addi	a1,a1,-1128 # 80008870 <initcode>
    80001ce0:	6d28                	ld	a0,88(a0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	674080e7          	jalr	1652(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cea:	6785                	lui	a5,0x1
    80001cec:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cee:	70b8                	ld	a4,96(s1)
    80001cf0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf4:	70b8                	ld	a4,96(s1)
    80001cf6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf8:	4641                	li	a2,16
    80001cfa:	00006597          	auipc	a1,0x6
    80001cfe:	50658593          	addi	a1,a1,1286 # 80008200 <digits+0x1c0>
    80001d02:	17848513          	addi	a0,s1,376
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	116080e7          	jalr	278(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	50250513          	addi	a0,a0,1282 # 80008210 <digits+0x1d0>
    80001d16:	00002097          	auipc	ra,0x2
    80001d1a:	4e0080e7          	jalr	1248(ra) # 800041f6 <namei>
    80001d1e:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d22:	478d                	li	a5,3
    80001d24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f62080e7          	jalr	-158(ra) # 80000c8a <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	c64080e7          	jalr	-924(ra) # 800019ac <myproc>
    80001d50:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d52:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d54:	01204c63          	bgtz	s2,80001d6c <growproc+0x32>
  else if (n < 0)
    80001d58:	02094663          	bltz	s2,80001d84 <growproc+0x4a>
  p->sz = sz;
    80001d5c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d5e:	4501                	li	a0,0
}
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6902                	ld	s2,0(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d6c:	4691                	li	a3,4
    80001d6e:	00b90633          	add	a2,s2,a1
    80001d72:	6d28                	ld	a0,88(a0)
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	69c080e7          	jalr	1692(ra) # 80001410 <uvmalloc>
    80001d7c:	85aa                	mv	a1,a0
    80001d7e:	fd79                	bnez	a0,80001d5c <growproc+0x22>
      return -1;
    80001d80:	557d                	li	a0,-1
    80001d82:	bff9                	j	80001d60 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d84:	00b90633          	add	a2,s2,a1
    80001d88:	6d28                	ld	a0,88(a0)
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	63e080e7          	jalr	1598(ra) # 800013c8 <uvmdealloc>
    80001d92:	85aa                	mv	a1,a0
    80001d94:	b7e1                	j	80001d5c <growproc+0x22>

0000000080001d96 <fork>:
{
    80001d96:	7139                	addi	sp,sp,-64
    80001d98:	fc06                	sd	ra,56(sp)
    80001d9a:	f822                	sd	s0,48(sp)
    80001d9c:	f426                	sd	s1,40(sp)
    80001d9e:	f04a                	sd	s2,32(sp)
    80001da0:	ec4e                	sd	s3,24(sp)
    80001da2:	e852                	sd	s4,16(sp)
    80001da4:	e456                	sd	s5,8(sp)
    80001da6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	c04080e7          	jalr	-1020(ra) # 800019ac <myproc>
    80001db0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	e04080e7          	jalr	-508(ra) # 80001bb6 <allocproc>
    80001dba:	10050c63          	beqz	a0,80001ed2 <fork+0x13c>
    80001dbe:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dc0:	048ab603          	ld	a2,72(s5)
    80001dc4:	6d2c                	ld	a1,88(a0)
    80001dc6:	058ab503          	ld	a0,88(s5)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	79a080e7          	jalr	1946(ra) # 80001564 <uvmcopy>
    80001dd2:	04054863          	bltz	a0,80001e22 <fork+0x8c>
  np->sz = p->sz;
    80001dd6:	048ab783          	ld	a5,72(s5)
    80001dda:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dde:	060ab683          	ld	a3,96(s5)
    80001de2:	87b6                	mv	a5,a3
    80001de4:	060a3703          	ld	a4,96(s4)
    80001de8:	12068693          	addi	a3,a3,288
    80001dec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df0:	6788                	ld	a0,8(a5)
    80001df2:	6b8c                	ld	a1,16(a5)
    80001df4:	6f90                	ld	a2,24(a5)
    80001df6:	01073023          	sd	a6,0(a4)
    80001dfa:	e708                	sd	a0,8(a4)
    80001dfc:	eb0c                	sd	a1,16(a4)
    80001dfe:	ef10                	sd	a2,24(a4)
    80001e00:	02078793          	addi	a5,a5,32
    80001e04:	02070713          	addi	a4,a4,32
    80001e08:	fed792e3          	bne	a5,a3,80001dec <fork+0x56>
  np->trapframe->a0 = 0;
    80001e0c:	060a3783          	ld	a5,96(s4)
    80001e10:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e14:	0f0a8493          	addi	s1,s5,240
    80001e18:	0f0a0913          	addi	s2,s4,240
    80001e1c:	170a8993          	addi	s3,s5,368
    80001e20:	a00d                	j	80001e42 <fork+0xac>
    freeproc(np);
    80001e22:	8552                	mv	a0,s4
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	d3a080e7          	jalr	-710(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e2c:	8552                	mv	a0,s4
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	e5c080e7          	jalr	-420(ra) # 80000c8a <release>
    return -1;
    80001e36:	597d                	li	s2,-1
    80001e38:	a059                	j	80001ebe <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e3a:	04a1                	addi	s1,s1,8
    80001e3c:	0921                	addi	s2,s2,8
    80001e3e:	01348b63          	beq	s1,s3,80001e54 <fork+0xbe>
    if (p->ofile[i])
    80001e42:	6088                	ld	a0,0(s1)
    80001e44:	d97d                	beqz	a0,80001e3a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e46:	00003097          	auipc	ra,0x3
    80001e4a:	a46080e7          	jalr	-1466(ra) # 8000488c <filedup>
    80001e4e:	00a93023          	sd	a0,0(s2)
    80001e52:	b7e5                	j	80001e3a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e54:	170ab503          	ld	a0,368(s5)
    80001e58:	00002097          	auipc	ra,0x2
    80001e5c:	bba080e7          	jalr	-1094(ra) # 80003a12 <idup>
    80001e60:	16aa3823          	sd	a0,368(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e64:	4641                	li	a2,16
    80001e66:	178a8593          	addi	a1,s5,376
    80001e6a:	178a0513          	addi	a0,s4,376
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	fae080e7          	jalr	-82(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e76:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e7a:	8552                	mv	a0,s4
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e84:	0000f497          	auipc	s1,0xf
    80001e88:	ce448493          	addi	s1,s1,-796 # 80010b68 <wait_lock>
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	d48080e7          	jalr	-696(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e96:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dee080e7          	jalr	-530(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d30080e7          	jalr	-720(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eae:	478d                	li	a5,3
    80001eb0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb4:	8552                	mv	a0,s4
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
}
    80001ebe:	854a                	mv	a0,s2
    80001ec0:	70e2                	ld	ra,56(sp)
    80001ec2:	7442                	ld	s0,48(sp)
    80001ec4:	74a2                	ld	s1,40(sp)
    80001ec6:	7902                	ld	s2,32(sp)
    80001ec8:	69e2                	ld	s3,24(sp)
    80001eca:	6a42                	ld	s4,16(sp)
    80001ecc:	6aa2                	ld	s5,8(sp)
    80001ece:	6121                	addi	sp,sp,64
    80001ed0:	8082                	ret
    return -1;
    80001ed2:	597d                	li	s2,-1
    80001ed4:	b7ed                	j	80001ebe <fork+0x128>

0000000080001ed6 <scheduler>:
{
    80001ed6:	7159                	addi	sp,sp,-112
    80001ed8:	f486                	sd	ra,104(sp)
    80001eda:	f0a2                	sd	s0,96(sp)
    80001edc:	eca6                	sd	s1,88(sp)
    80001ede:	e8ca                	sd	s2,80(sp)
    80001ee0:	e4ce                	sd	s3,72(sp)
    80001ee2:	e0d2                	sd	s4,64(sp)
    80001ee4:	fc56                	sd	s5,56(sp)
    80001ee6:	f85a                	sd	s6,48(sp)
    80001ee8:	f45e                	sd	s7,40(sp)
    80001eea:	f062                	sd	s8,32(sp)
    80001eec:	ec66                	sd	s9,24(sp)
    80001eee:	e86a                	sd	s10,16(sp)
    80001ef0:	e46e                	sd	s11,8(sp)
    80001ef2:	1880                	addi	s0,sp,112
    80001ef4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef6:	2781                	sext.w	a5,a5
    c->proc = 0;
    80001ef8:	00779d13          	slli	s10,a5,0x7
    80001efc:	0000f717          	auipc	a4,0xf
    80001f00:	c5470713          	addi	a4,a4,-940 # 80010b50 <pid_lock>
    80001f04:	976a                	add	a4,a4,s10
    80001f06:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &temp_proc->context);
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	c7e70713          	addi	a4,a4,-898 # 80010b88 <cpus+0x8>
    80001f12:	9d3a                	add	s10,s10,a4
        struct proc *temp_proc = NULL;
    80001f14:	4c81                	li	s9,0
      if (p->state != RUNNABLE)
    80001f16:	4b8d                	li	s7,3
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f18:	00015b17          	auipc	s6,0x15
    80001f1c:	668b0b13          	addi	s6,s6,1640 # 80017580 <tickslock>
      temp_proc->state = RUNNING;
    80001f20:	4d91                	li	s11,4
      c->proc = temp_proc;
    80001f22:	079e                	slli	a5,a5,0x7
    80001f24:	0000fc17          	auipc	s8,0xf
    80001f28:	c2cc0c13          	addi	s8,s8,-980 # 80010b50 <pid_lock>
    80001f2c:	9c3e                	add	s8,s8,a5
    80001f2e:	a825                	j	80001f66 <scheduler+0x90>
        release(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d58080e7          	jalr	-680(ra) # 80000c8a <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f3a:	05696e63          	bltu	s2,s6,80001f96 <scheduler+0xc0>
    if (temp_proc)
    80001f3e:	020a8463          	beqz	s5,80001f66 <scheduler+0x90>
      temp_proc->state = RUNNING;
    80001f42:	01baac23          	sw	s11,24(s5)
      c->proc = temp_proc;
    80001f46:	035c3823          	sd	s5,48(s8)
      swtch(&c->context, &temp_proc->context);
    80001f4a:	080a8593          	addi	a1,s5,128
    80001f4e:	856a                	mv	a0,s10
    80001f50:	00001097          	auipc	ra,0x1
    80001f54:	8ac080e7          	jalr	-1876(ra) # 800027fc <swtch>
      c->proc = 0;
    80001f58:	020c3823          	sd	zero,48(s8)
      release(&temp_proc->lock);
    80001f5c:	8556                	mv	a0,s5
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	d2c080e7          	jalr	-724(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6e:	10079073          	csrw	sstatus,a5
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f72:	0000f497          	auipc	s1,0xf
    80001f76:	00e48493          	addi	s1,s1,14 # 80010f80 <proc>
    80001f7a:	0000f917          	auipc	s2,0xf
    80001f7e:	19e90913          	addi	s2,s2,414 # 80011118 <proc+0x198>
        struct proc *temp_proc = NULL;
    80001f82:	8ae6                	mv	s5,s9
    80001f84:	a829                	j	80001f9e <scheduler+0xc8>
          release(&temp_proc->lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d02080e7          	jalr	-766(ra) # 80000c8a <release>
          continue;
    80001f90:	8aa6                	mv	s5,s1
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80001f92:	fb69f8e3          	bgeu	s3,s6,80001f42 <scheduler+0x6c>
    80001f96:	19848493          	addi	s1,s1,408
    80001f9a:	19890913          	addi	s2,s2,408
      acquire(&p->lock);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	c36080e7          	jalr	-970(ra) # 80000bd6 <acquire>
      if (p->state != RUNNABLE)
    80001fa8:	89ca                	mv	s3,s2
    80001faa:	e8092783          	lw	a5,-384(s2)
    80001fae:	f97791e3          	bne	a5,s7,80001f30 <scheduler+0x5a>
        if (!temp_proc)
    80001fb2:	000a8e63          	beqz	s5,80001fce <scheduler+0xf8>
        if (temp_proc->creation_time > p->creation_time)
    80001fb6:	188aa703          	lw	a4,392(s5)
    80001fba:	ff092783          	lw	a5,-16(s2)
    80001fbe:	fce7e4e3          	bltu	a5,a4,80001f86 <scheduler+0xb0>
      release(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cc6080e7          	jalr	-826(ra) # 80000c8a <release>
    80001fcc:	b7d9                	j	80001f92 <scheduler+0xbc>
    80001fce:	8aa6                	mv	s5,s1
    80001fd0:	b7c9                	j	80001f92 <scheduler+0xbc>

0000000080001fd2 <sched>:
{
    80001fd2:	7179                	addi	sp,sp,-48
    80001fd4:	f406                	sd	ra,40(sp)
    80001fd6:	f022                	sd	s0,32(sp)
    80001fd8:	ec26                	sd	s1,24(sp)
    80001fda:	e84a                	sd	s2,16(sp)
    80001fdc:	e44e                	sd	s3,8(sp)
    80001fde:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	9cc080e7          	jalr	-1588(ra) # 800019ac <myproc>
    80001fe8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	b72080e7          	jalr	-1166(ra) # 80000b5c <holding>
    80001ff2:	c93d                	beqz	a0,80002068 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	b5670713          	addi	a4,a4,-1194 # 80010b50 <pid_lock>
    80002002:	97ba                	add	a5,a5,a4
    80002004:	0a87a703          	lw	a4,168(a5)
    80002008:	4785                	li	a5,1
    8000200a:	06f71763          	bne	a4,a5,80002078 <sched+0xa6>
  if (p->state == RUNNING)
    8000200e:	4c98                	lw	a4,24(s1)
    80002010:	4791                	li	a5,4
    80002012:	06f70b63          	beq	a4,a5,80002088 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002016:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201a:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000201c:	efb5                	bnez	a5,80002098 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002020:	0000f917          	auipc	s2,0xf
    80002024:	b3090913          	addi	s2,s2,-1232 # 80010b50 <pid_lock>
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	97ca                	add	a5,a5,s2
    8000202e:	0ac7a983          	lw	s3,172(a5)
    80002032:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	0000f597          	auipc	a1,0xf
    8000203c:	b5058593          	addi	a1,a1,-1200 # 80010b88 <cpus+0x8>
    80002040:	95be                	add	a1,a1,a5
    80002042:	08048513          	addi	a0,s1,128
    80002046:	00000097          	auipc	ra,0x0
    8000204a:	7b6080e7          	jalr	1974(ra) # 800027fc <swtch>
    8000204e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	97ca                	add	a5,a5,s2
    80002056:	0b37a623          	sw	s3,172(a5)
}
    8000205a:	70a2                	ld	ra,40(sp)
    8000205c:	7402                	ld	s0,32(sp)
    8000205e:	64e2                	ld	s1,24(sp)
    80002060:	6942                	ld	s2,16(sp)
    80002062:	69a2                	ld	s3,8(sp)
    80002064:	6145                	addi	sp,sp,48
    80002066:	8082                	ret
    panic("sched p->lock");
    80002068:	00006517          	auipc	a0,0x6
    8000206c:	1b050513          	addi	a0,a0,432 # 80008218 <digits+0x1d8>
    80002070:	ffffe097          	auipc	ra,0xffffe
    80002074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>
    panic("sched locks");
    80002078:	00006517          	auipc	a0,0x6
    8000207c:	1b050513          	addi	a0,a0,432 # 80008228 <digits+0x1e8>
    80002080:	ffffe097          	auipc	ra,0xffffe
    80002084:	4be080e7          	jalr	1214(ra) # 8000053e <panic>
    panic("sched running");
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	1b050513          	addi	a0,a0,432 # 80008238 <digits+0x1f8>
    80002090:	ffffe097          	auipc	ra,0xffffe
    80002094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	1b050513          	addi	a0,a0,432 # 80008248 <digits+0x208>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>

00000000800020a8 <yield>:
{
    800020a8:	1101                	addi	sp,sp,-32
    800020aa:	ec06                	sd	ra,24(sp)
    800020ac:	e822                	sd	s0,16(sp)
    800020ae:	e426                	sd	s1,8(sp)
    800020b0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	8fa080e7          	jalr	-1798(ra) # 800019ac <myproc>
    800020ba:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020c4:	478d                	li	a5,3
    800020c6:	cc9c                	sw	a5,24(s1)
  sched();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	f0a080e7          	jalr	-246(ra) # 80001fd2 <sched>
  release(&p->lock);
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	bb8080e7          	jalr	-1096(ra) # 80000c8a <release>
}
    800020da:	60e2                	ld	ra,24(sp)
    800020dc:	6442                	ld	s0,16(sp)
    800020de:	64a2                	ld	s1,8(sp)
    800020e0:	6105                	addi	sp,sp,32
    800020e2:	8082                	ret

00000000800020e4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020e4:	7179                	addi	sp,sp,-48
    800020e6:	f406                	sd	ra,40(sp)
    800020e8:	f022                	sd	s0,32(sp)
    800020ea:	ec26                	sd	s1,24(sp)
    800020ec:	e84a                	sd	s2,16(sp)
    800020ee:	e44e                	sd	s3,8(sp)
    800020f0:	1800                	addi	s0,sp,48
    800020f2:	89aa                	mv	s3,a0
    800020f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	8b6080e7          	jalr	-1866(ra) # 800019ac <myproc>
    800020fe:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	ad6080e7          	jalr	-1322(ra) # 80000bd6 <acquire>
  release(lk);
    80002108:	854a                	mv	a0,s2
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	b80080e7          	jalr	-1152(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002112:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002116:	4789                	li	a5,2
    80002118:	cc9c                	sw	a5,24(s1)

  sched();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	eb8080e7          	jalr	-328(ra) # 80001fd2 <sched>

  // Tidy up.
  p->chan = 0;
    80002122:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b62080e7          	jalr	-1182(ra) # 80000c8a <release>
  acquire(lk);
    80002130:	854a                	mv	a0,s2
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	aa4080e7          	jalr	-1372(ra) # 80000bd6 <acquire>
}
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6145                	addi	sp,sp,48
    80002146:	8082                	ret

0000000080002148 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002148:	7139                	addi	sp,sp,-64
    8000214a:	fc06                	sd	ra,56(sp)
    8000214c:	f822                	sd	s0,48(sp)
    8000214e:	f426                	sd	s1,40(sp)
    80002150:	f04a                	sd	s2,32(sp)
    80002152:	ec4e                	sd	s3,24(sp)
    80002154:	e852                	sd	s4,16(sp)
    80002156:	e456                	sd	s5,8(sp)
    80002158:	0080                	addi	s0,sp,64
    8000215a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000215c:	0000f497          	auipc	s1,0xf
    80002160:	e2448493          	addi	s1,s1,-476 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002164:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002166:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002168:	00015917          	auipc	s2,0x15
    8000216c:	41890913          	addi	s2,s2,1048 # 80017580 <tickslock>
    80002170:	a811                	j	80002184 <wakeup+0x3c>
      }
      release(&p->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b16080e7          	jalr	-1258(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000217c:	19848493          	addi	s1,s1,408
    80002180:	03248663          	beq	s1,s2,800021ac <wakeup+0x64>
    if (p != myproc())
    80002184:	00000097          	auipc	ra,0x0
    80002188:	828080e7          	jalr	-2008(ra) # 800019ac <myproc>
    8000218c:	fea488e3          	beq	s1,a0,8000217c <wakeup+0x34>
      acquire(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000219a:	4c9c                	lw	a5,24(s1)
    8000219c:	fd379be3          	bne	a5,s3,80002172 <wakeup+0x2a>
    800021a0:	709c                	ld	a5,32(s1)
    800021a2:	fd4798e3          	bne	a5,s4,80002172 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021a6:	0154ac23          	sw	s5,24(s1)
    800021aa:	b7e1                	j	80002172 <wakeup+0x2a>
    }
  }
}
    800021ac:	70e2                	ld	ra,56(sp)
    800021ae:	7442                	ld	s0,48(sp)
    800021b0:	74a2                	ld	s1,40(sp)
    800021b2:	7902                	ld	s2,32(sp)
    800021b4:	69e2                	ld	s3,24(sp)
    800021b6:	6a42                	ld	s4,16(sp)
    800021b8:	6aa2                	ld	s5,8(sp)
    800021ba:	6121                	addi	sp,sp,64
    800021bc:	8082                	ret

00000000800021be <reparent>:
{
    800021be:	7179                	addi	sp,sp,-48
    800021c0:	f406                	sd	ra,40(sp)
    800021c2:	f022                	sd	s0,32(sp)
    800021c4:	ec26                	sd	s1,24(sp)
    800021c6:	e84a                	sd	s2,16(sp)
    800021c8:	e44e                	sd	s3,8(sp)
    800021ca:	e052                	sd	s4,0(sp)
    800021cc:	1800                	addi	s0,sp,48
    800021ce:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021d0:	0000f497          	auipc	s1,0xf
    800021d4:	db048493          	addi	s1,s1,-592 # 80010f80 <proc>
      pp->parent = initproc;
    800021d8:	00006a17          	auipc	s4,0x6
    800021dc:	700a0a13          	addi	s4,s4,1792 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021e0:	00015997          	auipc	s3,0x15
    800021e4:	3a098993          	addi	s3,s3,928 # 80017580 <tickslock>
    800021e8:	a029                	j	800021f2 <reparent+0x34>
    800021ea:	19848493          	addi	s1,s1,408
    800021ee:	01348d63          	beq	s1,s3,80002208 <reparent+0x4a>
    if (pp->parent == p)
    800021f2:	7c9c                	ld	a5,56(s1)
    800021f4:	ff279be3          	bne	a5,s2,800021ea <reparent+0x2c>
      pp->parent = initproc;
    800021f8:	000a3503          	ld	a0,0(s4)
    800021fc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	f4a080e7          	jalr	-182(ra) # 80002148 <wakeup>
    80002206:	b7d5                	j	800021ea <reparent+0x2c>
}
    80002208:	70a2                	ld	ra,40(sp)
    8000220a:	7402                	ld	s0,32(sp)
    8000220c:	64e2                	ld	s1,24(sp)
    8000220e:	6942                	ld	s2,16(sp)
    80002210:	69a2                	ld	s3,8(sp)
    80002212:	6a02                	ld	s4,0(sp)
    80002214:	6145                	addi	sp,sp,48
    80002216:	8082                	ret

0000000080002218 <exit>:
{
    80002218:	7179                	addi	sp,sp,-48
    8000221a:	f406                	sd	ra,40(sp)
    8000221c:	f022                	sd	s0,32(sp)
    8000221e:	ec26                	sd	s1,24(sp)
    80002220:	e84a                	sd	s2,16(sp)
    80002222:	e44e                	sd	s3,8(sp)
    80002224:	e052                	sd	s4,0(sp)
    80002226:	1800                	addi	s0,sp,48
    80002228:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	782080e7          	jalr	1922(ra) # 800019ac <myproc>
    80002232:	89aa                	mv	s3,a0
  if (p == initproc)
    80002234:	00006797          	auipc	a5,0x6
    80002238:	6a47b783          	ld	a5,1700(a5) # 800088d8 <initproc>
    8000223c:	0f050493          	addi	s1,a0,240
    80002240:	17050913          	addi	s2,a0,368
    80002244:	02a79363          	bne	a5,a0,8000226a <exit+0x52>
    panic("init exiting");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	01850513          	addi	a0,a0,24 # 80008260 <digits+0x220>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2ee080e7          	jalr	750(ra) # 8000053e <panic>
      fileclose(f);
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	686080e7          	jalr	1670(ra) # 800048de <fileclose>
      p->ofile[fd] = 0;
    80002260:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002264:	04a1                	addi	s1,s1,8
    80002266:	01248563          	beq	s1,s2,80002270 <exit+0x58>
    if (p->ofile[fd])
    8000226a:	6088                	ld	a0,0(s1)
    8000226c:	f575                	bnez	a0,80002258 <exit+0x40>
    8000226e:	bfdd                	j	80002264 <exit+0x4c>
  begin_op();
    80002270:	00002097          	auipc	ra,0x2
    80002274:	1a2080e7          	jalr	418(ra) # 80004412 <begin_op>
  iput(p->cwd);
    80002278:	1709b503          	ld	a0,368(s3)
    8000227c:	00002097          	auipc	ra,0x2
    80002280:	98e080e7          	jalr	-1650(ra) # 80003c0a <iput>
  end_op();
    80002284:	00002097          	auipc	ra,0x2
    80002288:	20e080e7          	jalr	526(ra) # 80004492 <end_op>
  p->cwd = 0;
    8000228c:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	8d848493          	addi	s1,s1,-1832 # 80010b68 <wait_lock>
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	93c080e7          	jalr	-1732(ra) # 80000bd6 <acquire>
  reparent(p);
    800022a2:	854e                	mv	a0,s3
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	f1a080e7          	jalr	-230(ra) # 800021be <reparent>
  wakeup(p->parent);
    800022ac:	0389b503          	ld	a0,56(s3)
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	e98080e7          	jalr	-360(ra) # 80002148 <wakeup>
  acquire(&p->lock);
    800022b8:	854e                	mv	a0,s3
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	91c080e7          	jalr	-1764(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022c2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022c6:	4795                	li	a5,5
    800022c8:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022cc:	00006797          	auipc	a5,0x6
    800022d0:	6147a783          	lw	a5,1556(a5) # 800088e0 <ticks>
    800022d4:	18f9aa23          	sw	a5,404(s3)
  release(&wait_lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9b0080e7          	jalr	-1616(ra) # 80000c8a <release>
  sched();
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	cf0080e7          	jalr	-784(ra) # 80001fd2 <sched>
  panic("zombie exit");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	f8650513          	addi	a0,a0,-122 # 80008270 <digits+0x230>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>

00000000800022fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022fa:	7179                	addi	sp,sp,-48
    800022fc:	f406                	sd	ra,40(sp)
    800022fe:	f022                	sd	s0,32(sp)
    80002300:	ec26                	sd	s1,24(sp)
    80002302:	e84a                	sd	s2,16(sp)
    80002304:	e44e                	sd	s3,8(sp)
    80002306:	1800                	addi	s0,sp,48
    80002308:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000230a:	0000f497          	auipc	s1,0xf
    8000230e:	c7648493          	addi	s1,s1,-906 # 80010f80 <proc>
    80002312:	00015997          	auipc	s3,0x15
    80002316:	26e98993          	addi	s3,s3,622 # 80017580 <tickslock>
  {
    acquire(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8ba080e7          	jalr	-1862(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002324:	589c                	lw	a5,48(s1)
    80002326:	01278d63          	beq	a5,s2,80002340 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	95e080e7          	jalr	-1698(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002334:	19848493          	addi	s1,s1,408
    80002338:	ff3491e3          	bne	s1,s3,8000231a <kill+0x20>
  }
  return -1;
    8000233c:	557d                	li	a0,-1
    8000233e:	a829                	j	80002358 <kill+0x5e>
      p->killed = 1;
    80002340:	4785                	li	a5,1
    80002342:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002344:	4c98                	lw	a4,24(s1)
    80002346:	4789                	li	a5,2
    80002348:	00f70f63          	beq	a4,a5,80002366 <kill+0x6c>
      release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
      return 0;
    80002356:	4501                	li	a0,0
}
    80002358:	70a2                	ld	ra,40(sp)
    8000235a:	7402                	ld	s0,32(sp)
    8000235c:	64e2                	ld	s1,24(sp)
    8000235e:	6942                	ld	s2,16(sp)
    80002360:	69a2                	ld	s3,8(sp)
    80002362:	6145                	addi	sp,sp,48
    80002364:	8082                	ret
        p->state = RUNNABLE;
    80002366:	478d                	li	a5,3
    80002368:	cc9c                	sw	a5,24(s1)
    8000236a:	b7cd                	j	8000234c <kill+0x52>

000000008000236c <setkilled>:

void setkilled(struct proc *p)
{
    8000236c:	1101                	addi	sp,sp,-32
    8000236e:	ec06                	sd	ra,24(sp)
    80002370:	e822                	sd	s0,16(sp)
    80002372:	e426                	sd	s1,8(sp)
    80002374:	1000                	addi	s0,sp,32
    80002376:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002380:	4785                	li	a5,1
    80002382:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
}
    8000238e:	60e2                	ld	ra,24(sp)
    80002390:	6442                	ld	s0,16(sp)
    80002392:	64a2                	ld	s1,8(sp)
    80002394:	6105                	addi	sp,sp,32
    80002396:	8082                	ret

0000000080002398 <killed>:

int killed(struct proc *p)
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	e04a                	sd	s2,0(sp)
    800023a2:	1000                	addi	s0,sp,32
    800023a4:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023ae:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
  return k;
}
    800023bc:	854a                	mv	a0,s2
    800023be:	60e2                	ld	ra,24(sp)
    800023c0:	6442                	ld	s0,16(sp)
    800023c2:	64a2                	ld	s1,8(sp)
    800023c4:	6902                	ld	s2,0(sp)
    800023c6:	6105                	addi	sp,sp,32
    800023c8:	8082                	ret

00000000800023ca <wait>:
{
    800023ca:	715d                	addi	sp,sp,-80
    800023cc:	e486                	sd	ra,72(sp)
    800023ce:	e0a2                	sd	s0,64(sp)
    800023d0:	fc26                	sd	s1,56(sp)
    800023d2:	f84a                	sd	s2,48(sp)
    800023d4:	f44e                	sd	s3,40(sp)
    800023d6:	f052                	sd	s4,32(sp)
    800023d8:	ec56                	sd	s5,24(sp)
    800023da:	e85a                	sd	s6,16(sp)
    800023dc:	e45e                	sd	s7,8(sp)
    800023de:	e062                	sd	s8,0(sp)
    800023e0:	0880                	addi	s0,sp,80
    800023e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	5c8080e7          	jalr	1480(ra) # 800019ac <myproc>
    800023ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ee:	0000e517          	auipc	a0,0xe
    800023f2:	77a50513          	addi	a0,a0,1914 # 80010b68 <wait_lock>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7e0080e7          	jalr	2016(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023fe:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002400:	4a15                	li	s4,5
        havekids = 1;
    80002402:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002404:	00015997          	auipc	s3,0x15
    80002408:	17c98993          	addi	s3,s3,380 # 80017580 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000240c:	0000ec17          	auipc	s8,0xe
    80002410:	75cc0c13          	addi	s8,s8,1884 # 80010b68 <wait_lock>
    havekids = 0;
    80002414:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002416:	0000f497          	auipc	s1,0xf
    8000241a:	b6a48493          	addi	s1,s1,-1174 # 80010f80 <proc>
    8000241e:	a0bd                	j	8000248c <wait+0xc2>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x76>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05893503          	ld	a0,88(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	234080e7          	jalr	564(ra) # 80001668 <copyout>
    8000243c:	02054563          	bltz	a0,80002466 <wait+0x9c>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	71c080e7          	jalr	1820(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
          release(&wait_lock);
    80002454:	0000e517          	auipc	a0,0xe
    80002458:	71450513          	addi	a0,a0,1812 # 80010b68 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	82e080e7          	jalr	-2002(ra) # 80000c8a <release>
          return pid;
    80002464:	a0b5                	j	800024d0 <wait+0x106>
            release(&pp->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
            release(&wait_lock);
    80002470:	0000e517          	auipc	a0,0xe
    80002474:	6f850513          	addi	a0,a0,1784 # 80010b68 <wait_lock>
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	812080e7          	jalr	-2030(ra) # 80000c8a <release>
            return -1;
    80002480:	59fd                	li	s3,-1
    80002482:	a0b9                	j	800024d0 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002484:	19848493          	addi	s1,s1,408
    80002488:	03348463          	beq	s1,s3,800024b0 <wait+0xe6>
      if (pp->parent == p)
    8000248c:	7c9c                	ld	a5,56(s1)
    8000248e:	ff279be3          	bne	a5,s2,80002484 <wait+0xba>
        acquire(&pp->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	742080e7          	jalr	1858(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000249c:	4c9c                	lw	a5,24(s1)
    8000249e:	f94781e3          	beq	a5,s4,80002420 <wait+0x56>
        release(&pp->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7e6080e7          	jalr	2022(ra) # 80000c8a <release>
        havekids = 1;
    800024ac:	8756                	mv	a4,s5
    800024ae:	bfd9                	j	80002484 <wait+0xba>
    if (!havekids || killed(p))
    800024b0:	c719                	beqz	a4,800024be <wait+0xf4>
    800024b2:	854a                	mv	a0,s2
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	ee4080e7          	jalr	-284(ra) # 80002398 <killed>
    800024bc:	c51d                	beqz	a0,800024ea <wait+0x120>
      release(&wait_lock);
    800024be:	0000e517          	auipc	a0,0xe
    800024c2:	6aa50513          	addi	a0,a0,1706 # 80010b68 <wait_lock>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7c4080e7          	jalr	1988(ra) # 80000c8a <release>
      return -1;
    800024ce:	59fd                	li	s3,-1
}
    800024d0:	854e                	mv	a0,s3
    800024d2:	60a6                	ld	ra,72(sp)
    800024d4:	6406                	ld	s0,64(sp)
    800024d6:	74e2                	ld	s1,56(sp)
    800024d8:	7942                	ld	s2,48(sp)
    800024da:	79a2                	ld	s3,40(sp)
    800024dc:	7a02                	ld	s4,32(sp)
    800024de:	6ae2                	ld	s5,24(sp)
    800024e0:	6b42                	ld	s6,16(sp)
    800024e2:	6ba2                	ld	s7,8(sp)
    800024e4:	6c02                	ld	s8,0(sp)
    800024e6:	6161                	addi	sp,sp,80
    800024e8:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024ea:	85e2                	mv	a1,s8
    800024ec:	854a                	mv	a0,s2
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	bf6080e7          	jalr	-1034(ra) # 800020e4 <sleep>
    havekids = 0;
    800024f6:	bf39                	j	80002414 <wait+0x4a>

00000000800024f8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	84aa                	mv	s1,a0
    8000250a:	892e                	mv	s2,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	49c080e7          	jalr	1180(ra) # 800019ac <myproc>
  if (user_dst)
    80002518:	c08d                	beqz	s1,8000253a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000251a:	86d2                	mv	a3,s4
    8000251c:	864e                	mv	a2,s3
    8000251e:	85ca                	mv	a1,s2
    80002520:	6d28                	ld	a0,88(a0)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	146080e7          	jalr	326(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    memmove((char *)dst, src, len);
    8000253a:	000a061b          	sext.w	a2,s4
    8000253e:	85ce                	mv	a1,s3
    80002540:	854a                	mv	a0,s2
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	7ec080e7          	jalr	2028(ra) # 80000d2e <memmove>
    return 0;
    8000254a:	8526                	mv	a0,s1
    8000254c:	bff9                	j	8000252a <either_copyout+0x32>

000000008000254e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254e:	7179                	addi	sp,sp,-48
    80002550:	f406                	sd	ra,40(sp)
    80002552:	f022                	sd	s0,32(sp)
    80002554:	ec26                	sd	s1,24(sp)
    80002556:	e84a                	sd	s2,16(sp)
    80002558:	e44e                	sd	s3,8(sp)
    8000255a:	e052                	sd	s4,0(sp)
    8000255c:	1800                	addi	s0,sp,48
    8000255e:	892a                	mv	s2,a0
    80002560:	84ae                	mv	s1,a1
    80002562:	89b2                	mv	s3,a2
    80002564:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	446080e7          	jalr	1094(ra) # 800019ac <myproc>
  if (user_src)
    8000256e:	c08d                	beqz	s1,80002590 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002570:	86d2                	mv	a3,s4
    80002572:	864e                	mv	a2,s3
    80002574:	85ca                	mv	a1,s2
    80002576:	6d28                	ld	a0,88(a0)
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	17c080e7          	jalr	380(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002580:	70a2                	ld	ra,40(sp)
    80002582:	7402                	ld	s0,32(sp)
    80002584:	64e2                	ld	s1,24(sp)
    80002586:	6942                	ld	s2,16(sp)
    80002588:	69a2                	ld	s3,8(sp)
    8000258a:	6a02                	ld	s4,0(sp)
    8000258c:	6145                	addi	sp,sp,48
    8000258e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002590:	000a061b          	sext.w	a2,s4
    80002594:	85ce                	mv	a1,s3
    80002596:	854a                	mv	a0,s2
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	796080e7          	jalr	1942(ra) # 80000d2e <memmove>
    return 0;
    800025a0:	8526                	mv	a0,s1
    800025a2:	bff9                	j	80002580 <either_copyin+0x32>

00000000800025a4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025ba:	00006517          	auipc	a0,0x6
    800025be:	b0e50513          	addi	a0,a0,-1266 # 800080c8 <digits+0x88>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	fc6080e7          	jalr	-58(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ca:	0000f497          	auipc	s1,0xf
    800025ce:	b2e48493          	addi	s1,s1,-1234 # 800110f8 <proc+0x178>
    800025d2:	00015917          	auipc	s2,0x15
    800025d6:	12690913          	addi	s2,s2,294 # 800176f8 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025da:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025dc:	00006997          	auipc	s3,0x6
    800025e0:	ca498993          	addi	s3,s3,-860 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025e4:	00006a97          	auipc	s5,0x6
    800025e8:	ca4a8a93          	addi	s5,s5,-860 # 80008288 <digits+0x248>
    printf("\n");
    800025ec:	00006a17          	auipc	s4,0x6
    800025f0:	adca0a13          	addi	s4,s4,-1316 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	00006b97          	auipc	s7,0x6
    800025f8:	cd4b8b93          	addi	s7,s7,-812 # 800082c8 <states.0>
    800025fc:	a00d                	j	8000261e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fe:	eb86a583          	lw	a1,-328(a3)
    80002602:	8556                	mv	a0,s5
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	f84080e7          	jalr	-124(ra) # 80000588 <printf>
    printf("\n");
    8000260c:	8552                	mv	a0,s4
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7a080e7          	jalr	-134(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002616:	19848493          	addi	s1,s1,408
    8000261a:	03248163          	beq	s1,s2,8000263c <procdump+0x98>
    if (p->state == UNUSED)
    8000261e:	86a6                	mv	a3,s1
    80002620:	ea04a783          	lw	a5,-352(s1)
    80002624:	dbed                	beqz	a5,80002616 <procdump+0x72>
      state = "???";
    80002626:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002628:	fcfb6be3          	bltu	s6,a5,800025fe <procdump+0x5a>
    8000262c:	1782                	slli	a5,a5,0x20
    8000262e:	9381                	srli	a5,a5,0x20
    80002630:	078e                	slli	a5,a5,0x3
    80002632:	97de                	add	a5,a5,s7
    80002634:	6390                	ld	a2,0(a5)
    80002636:	f661                	bnez	a2,800025fe <procdump+0x5a>
      state = "???";
    80002638:	864e                	mv	a2,s3
    8000263a:	b7d1                	j	800025fe <procdump+0x5a>
  }
}
    8000263c:	60a6                	ld	ra,72(sp)
    8000263e:	6406                	ld	s0,64(sp)
    80002640:	74e2                	ld	s1,56(sp)
    80002642:	7942                	ld	s2,48(sp)
    80002644:	79a2                	ld	s3,40(sp)
    80002646:	7a02                	ld	s4,32(sp)
    80002648:	6ae2                	ld	s5,24(sp)
    8000264a:	6b42                	ld	s6,16(sp)
    8000264c:	6ba2                	ld	s7,8(sp)
    8000264e:	6161                	addi	sp,sp,80
    80002650:	8082                	ret

0000000080002652 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002652:	711d                	addi	sp,sp,-96
    80002654:	ec86                	sd	ra,88(sp)
    80002656:	e8a2                	sd	s0,80(sp)
    80002658:	e4a6                	sd	s1,72(sp)
    8000265a:	e0ca                	sd	s2,64(sp)
    8000265c:	fc4e                	sd	s3,56(sp)
    8000265e:	f852                	sd	s4,48(sp)
    80002660:	f456                	sd	s5,40(sp)
    80002662:	f05a                	sd	s6,32(sp)
    80002664:	ec5e                	sd	s7,24(sp)
    80002666:	e862                	sd	s8,16(sp)
    80002668:	e466                	sd	s9,8(sp)
    8000266a:	e06a                	sd	s10,0(sp)
    8000266c:	1080                	addi	s0,sp,96
    8000266e:	8b2a                	mv	s6,a0
    80002670:	8bae                	mv	s7,a1
    80002672:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	338080e7          	jalr	824(ra) # 800019ac <myproc>
    8000267c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000267e:	0000e517          	auipc	a0,0xe
    80002682:	4ea50513          	addi	a0,a0,1258 # 80010b68 <wait_lock>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	550080e7          	jalr	1360(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000268e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002690:	4a15                	li	s4,5
        havekids = 1;
    80002692:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002694:	00015997          	auipc	s3,0x15
    80002698:	eec98993          	addi	s3,s3,-276 # 80017580 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000269c:	0000ed17          	auipc	s10,0xe
    800026a0:	4ccd0d13          	addi	s10,s10,1228 # 80010b68 <wait_lock>
    havekids = 0;
    800026a4:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800026a6:	0000f497          	auipc	s1,0xf
    800026aa:	8da48493          	addi	s1,s1,-1830 # 80010f80 <proc>
    800026ae:	a059                	j	80002734 <waitx+0xe2>
          pid = np->pid;
    800026b0:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800026b4:	18c4a703          	lw	a4,396(s1)
    800026b8:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800026bc:	1904a783          	lw	a5,400(s1)
    800026c0:	9f3d                	addw	a4,a4,a5
    800026c2:	1944a783          	lw	a5,404(s1)
    800026c6:	9f99                	subw	a5,a5,a4
    800026c8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026cc:	000b0e63          	beqz	s6,800026e8 <waitx+0x96>
    800026d0:	4691                	li	a3,4
    800026d2:	02c48613          	addi	a2,s1,44
    800026d6:	85da                	mv	a1,s6
    800026d8:	05893503          	ld	a0,88(s2)
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	f8c080e7          	jalr	-116(ra) # 80001668 <copyout>
    800026e4:	02054563          	bltz	a0,8000270e <waitx+0xbc>
          freeproc(np);
    800026e8:	8526                	mv	a0,s1
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	474080e7          	jalr	1140(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	596080e7          	jalr	1430(ra) # 80000c8a <release>
          release(&wait_lock);
    800026fc:	0000e517          	auipc	a0,0xe
    80002700:	46c50513          	addi	a0,a0,1132 # 80010b68 <wait_lock>
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	586080e7          	jalr	1414(ra) # 80000c8a <release>
          return pid;
    8000270c:	a09d                	j	80002772 <waitx+0x120>
            release(&np->lock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	57a080e7          	jalr	1402(ra) # 80000c8a <release>
            release(&wait_lock);
    80002718:	0000e517          	auipc	a0,0xe
    8000271c:	45050513          	addi	a0,a0,1104 # 80010b68 <wait_lock>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	56a080e7          	jalr	1386(ra) # 80000c8a <release>
            return -1;
    80002728:	59fd                	li	s3,-1
    8000272a:	a0a1                	j	80002772 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000272c:	19848493          	addi	s1,s1,408
    80002730:	03348463          	beq	s1,s3,80002758 <waitx+0x106>
      if (np->parent == p)
    80002734:	7c9c                	ld	a5,56(s1)
    80002736:	ff279be3          	bne	a5,s2,8000272c <waitx+0xda>
        acquire(&np->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	49a080e7          	jalr	1178(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002744:	4c9c                	lw	a5,24(s1)
    80002746:	f74785e3          	beq	a5,s4,800026b0 <waitx+0x5e>
        release(&np->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	53e080e7          	jalr	1342(ra) # 80000c8a <release>
        havekids = 1;
    80002754:	8756                	mv	a4,s5
    80002756:	bfd9                	j	8000272c <waitx+0xda>
    if (!havekids || p->killed)
    80002758:	c701                	beqz	a4,80002760 <waitx+0x10e>
    8000275a:	02892783          	lw	a5,40(s2)
    8000275e:	cb8d                	beqz	a5,80002790 <waitx+0x13e>
      release(&wait_lock);
    80002760:	0000e517          	auipc	a0,0xe
    80002764:	40850513          	addi	a0,a0,1032 # 80010b68 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	522080e7          	jalr	1314(ra) # 80000c8a <release>
      return -1;
    80002770:	59fd                	li	s3,-1
  }
}
    80002772:	854e                	mv	a0,s3
    80002774:	60e6                	ld	ra,88(sp)
    80002776:	6446                	ld	s0,80(sp)
    80002778:	64a6                	ld	s1,72(sp)
    8000277a:	6906                	ld	s2,64(sp)
    8000277c:	79e2                	ld	s3,56(sp)
    8000277e:	7a42                	ld	s4,48(sp)
    80002780:	7aa2                	ld	s5,40(sp)
    80002782:	7b02                	ld	s6,32(sp)
    80002784:	6be2                	ld	s7,24(sp)
    80002786:	6c42                	ld	s8,16(sp)
    80002788:	6ca2                	ld	s9,8(sp)
    8000278a:	6d02                	ld	s10,0(sp)
    8000278c:	6125                	addi	sp,sp,96
    8000278e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002790:	85ea                	mv	a1,s10
    80002792:	854a                	mv	a0,s2
    80002794:	00000097          	auipc	ra,0x0
    80002798:	950080e7          	jalr	-1712(ra) # 800020e4 <sleep>
    havekids = 0;
    8000279c:	b721                	j	800026a4 <waitx+0x52>

000000008000279e <update_time>:

void update_time()
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027ac:	0000e497          	auipc	s1,0xe
    800027b0:	7d448493          	addi	s1,s1,2004 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800027b4:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800027b6:	00015917          	auipc	s2,0x15
    800027ba:	dca90913          	addi	s2,s2,-566 # 80017580 <tickslock>
    800027be:	a811                	j	800027d2 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027ca:	19848493          	addi	s1,s1,408
    800027ce:	03248063          	beq	s1,s2,800027ee <update_time+0x50>
    acquire(&p->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800027dc:	4c9c                	lw	a5,24(s1)
    800027de:	ff3791e3          	bne	a5,s3,800027c0 <update_time+0x22>
      p->rtime++;
    800027e2:	18c4a783          	lw	a5,396(s1)
    800027e6:	2785                	addiw	a5,a5,1
    800027e8:	18f4a623          	sw	a5,396(s1)
    800027ec:	bfd1                	j	800027c0 <update_time+0x22>
  }
    800027ee:	70a2                	ld	ra,40(sp)
    800027f0:	7402                	ld	s0,32(sp)
    800027f2:	64e2                	ld	s1,24(sp)
    800027f4:	6942                	ld	s2,16(sp)
    800027f6:	69a2                	ld	s3,8(sp)
    800027f8:	6145                	addi	sp,sp,48
    800027fa:	8082                	ret

00000000800027fc <swtch>:
    800027fc:	00153023          	sd	ra,0(a0)
    80002800:	00253423          	sd	sp,8(a0)
    80002804:	e900                	sd	s0,16(a0)
    80002806:	ed04                	sd	s1,24(a0)
    80002808:	03253023          	sd	s2,32(a0)
    8000280c:	03353423          	sd	s3,40(a0)
    80002810:	03453823          	sd	s4,48(a0)
    80002814:	03553c23          	sd	s5,56(a0)
    80002818:	05653023          	sd	s6,64(a0)
    8000281c:	05753423          	sd	s7,72(a0)
    80002820:	05853823          	sd	s8,80(a0)
    80002824:	05953c23          	sd	s9,88(a0)
    80002828:	07a53023          	sd	s10,96(a0)
    8000282c:	07b53423          	sd	s11,104(a0)
    80002830:	0005b083          	ld	ra,0(a1)
    80002834:	0085b103          	ld	sp,8(a1)
    80002838:	6980                	ld	s0,16(a1)
    8000283a:	6d84                	ld	s1,24(a1)
    8000283c:	0205b903          	ld	s2,32(a1)
    80002840:	0285b983          	ld	s3,40(a1)
    80002844:	0305ba03          	ld	s4,48(a1)
    80002848:	0385ba83          	ld	s5,56(a1)
    8000284c:	0405bb03          	ld	s6,64(a1)
    80002850:	0485bb83          	ld	s7,72(a1)
    80002854:	0505bc03          	ld	s8,80(a1)
    80002858:	0585bc83          	ld	s9,88(a1)
    8000285c:	0605bd03          	ld	s10,96(a1)
    80002860:	0685bd83          	ld	s11,104(a1)
    80002864:	8082                	ret

0000000080002866 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002866:	1141                	addi	sp,sp,-16
    80002868:	e406                	sd	ra,8(sp)
    8000286a:	e022                	sd	s0,0(sp)
    8000286c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000286e:	00006597          	auipc	a1,0x6
    80002872:	a8a58593          	addi	a1,a1,-1398 # 800082f8 <states.0+0x30>
    80002876:	00015517          	auipc	a0,0x15
    8000287a:	d0a50513          	addi	a0,a0,-758 # 80017580 <tickslock>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	2c8080e7          	jalr	712(ra) # 80000b46 <initlock>
}
    80002886:	60a2                	ld	ra,8(sp)
    80002888:	6402                	ld	s0,0(sp)
    8000288a:	0141                	addi	sp,sp,16
    8000288c:	8082                	ret

000000008000288e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000288e:	1141                	addi	sp,sp,-16
    80002890:	e422                	sd	s0,8(sp)
    80002892:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002894:	00003797          	auipc	a5,0x3
    80002898:	69c78793          	addi	a5,a5,1692 # 80005f30 <kernelvec>
    8000289c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028a0:	6422                	ld	s0,8(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800028a6:	1141                	addi	sp,sp,-16
    800028a8:	e406                	sd	ra,8(sp)
    800028aa:	e022                	sd	s0,0(sp)
    800028ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	0fe080e7          	jalr	254(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028c0:	00004617          	auipc	a2,0x4
    800028c4:	74060613          	addi	a2,a2,1856 # 80007000 <_trampoline>
    800028c8:	00004697          	auipc	a3,0x4
    800028cc:	73868693          	addi	a3,a3,1848 # 80007000 <_trampoline>
    800028d0:	8e91                	sub	a3,a3,a2
    800028d2:	040007b7          	lui	a5,0x4000
    800028d6:	17fd                	addi	a5,a5,-1
    800028d8:	07b2                	slli	a5,a5,0xc
    800028da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028dc:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028e0:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028e2:	180026f3          	csrr	a3,satp
    800028e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028e8:	7138                	ld	a4,96(a0)
    800028ea:	6134                	ld	a3,64(a0)
    800028ec:	6585                	lui	a1,0x1
    800028ee:	96ae                	add	a3,a3,a1
    800028f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028f2:	7138                	ld	a4,96(a0)
    800028f4:	00000697          	auipc	a3,0x0
    800028f8:	13e68693          	addi	a3,a3,318 # 80002a32 <usertrap>
    800028fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028fe:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002900:	8692                	mv	a3,tp
    80002902:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002904:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002908:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000290c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002914:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002916:	6f18                	ld	a4,24(a4)
    80002918:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000291c:	6d28                	ld	a0,88(a0)
    8000291e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002920:	00004717          	auipc	a4,0x4
    80002924:	77c70713          	addi	a4,a4,1916 # 8000709c <userret>
    80002928:	8f11                	sub	a4,a4,a2
    8000292a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000292c:	577d                	li	a4,-1
    8000292e:	177e                	slli	a4,a4,0x3f
    80002930:	8d59                	or	a0,a0,a4
    80002932:	9782                	jalr	a5
}
    80002934:	60a2                	ld	ra,8(sp)
    80002936:	6402                	ld	s0,0(sp)
    80002938:	0141                	addi	sp,sp,16
    8000293a:	8082                	ret

000000008000293c <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    8000293c:	1101                	addi	sp,sp,-32
    8000293e:	ec06                	sd	ra,24(sp)
    80002940:	e822                	sd	s0,16(sp)
    80002942:	e426                	sd	s1,8(sp)
    80002944:	e04a                	sd	s2,0(sp)
    80002946:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002948:	00015917          	auipc	s2,0x15
    8000294c:	c3890913          	addi	s2,s2,-968 # 80017580 <tickslock>
    80002950:	854a                	mv	a0,s2
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	284080e7          	jalr	644(ra) # 80000bd6 <acquire>
  ticks++;
    8000295a:	00006497          	auipc	s1,0x6
    8000295e:	f8648493          	addi	s1,s1,-122 # 800088e0 <ticks>
    80002962:	409c                	lw	a5,0(s1)
    80002964:	2785                	addiw	a5,a5,1
    80002966:	c09c                	sw	a5,0(s1)
  update_time();
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	e36080e7          	jalr	-458(ra) # 8000279e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002970:	8526                	mv	a0,s1
    80002972:	fffff097          	auipc	ra,0xfffff
    80002976:	7d6080e7          	jalr	2006(ra) # 80002148 <wakeup>
  release(&tickslock);
    8000297a:	854a                	mv	a0,s2
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	30e080e7          	jalr	782(ra) # 80000c8a <release>
}
    80002984:	60e2                	ld	ra,24(sp)
    80002986:	6442                	ld	s0,16(sp)
    80002988:	64a2                	ld	s1,8(sp)
    8000298a:	6902                	ld	s2,0(sp)
    8000298c:	6105                	addi	sp,sp,32
    8000298e:	8082                	ret

0000000080002990 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002990:	1101                	addi	sp,sp,-32
    80002992:	ec06                	sd	ra,24(sp)
    80002994:	e822                	sd	s0,16(sp)
    80002996:	e426                	sd	s1,8(sp)
    80002998:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    8000299e:	00074d63          	bltz	a4,800029b8 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800029a2:	57fd                	li	a5,-1
    800029a4:	17fe                	slli	a5,a5,0x3f
    800029a6:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800029a8:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800029aa:	06f70363          	beq	a4,a5,80002a10 <devintr+0x80>
  }
}
    800029ae:	60e2                	ld	ra,24(sp)
    800029b0:	6442                	ld	s0,16(sp)
    800029b2:	64a2                	ld	s1,8(sp)
    800029b4:	6105                	addi	sp,sp,32
    800029b6:	8082                	ret
      (scause & 0xff) == 9)
    800029b8:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    800029bc:	46a5                	li	a3,9
    800029be:	fed792e3          	bne	a5,a3,800029a2 <devintr+0x12>
    int irq = plic_claim();
    800029c2:	00003097          	auipc	ra,0x3
    800029c6:	676080e7          	jalr	1654(ra) # 80006038 <plic_claim>
    800029ca:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800029cc:	47a9                	li	a5,10
    800029ce:	02f50763          	beq	a0,a5,800029fc <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800029d2:	4785                	li	a5,1
    800029d4:	02f50963          	beq	a0,a5,80002a06 <devintr+0x76>
    return 1;
    800029d8:	4505                	li	a0,1
    else if (irq)
    800029da:	d8f1                	beqz	s1,800029ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029dc:	85a6                	mv	a1,s1
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	92250513          	addi	a0,a0,-1758 # 80008300 <states.0+0x38>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	ba2080e7          	jalr	-1118(ra) # 80000588 <printf>
      plic_complete(irq);
    800029ee:	8526                	mv	a0,s1
    800029f0:	00003097          	auipc	ra,0x3
    800029f4:	66c080e7          	jalr	1644(ra) # 8000605c <plic_complete>
    return 1;
    800029f8:	4505                	li	a0,1
    800029fa:	bf55                	j	800029ae <devintr+0x1e>
      uartintr();
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	f9e080e7          	jalr	-98(ra) # 8000099a <uartintr>
    80002a04:	b7ed                	j	800029ee <devintr+0x5e>
      virtio_disk_intr();
    80002a06:	00004097          	auipc	ra,0x4
    80002a0a:	b22080e7          	jalr	-1246(ra) # 80006528 <virtio_disk_intr>
    80002a0e:	b7c5                	j	800029ee <devintr+0x5e>
    if (cpuid() == 0)
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	f70080e7          	jalr	-144(ra) # 80001980 <cpuid>
    80002a18:	c901                	beqz	a0,80002a28 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a1a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a20:	14479073          	csrw	sip,a5
    return 2;
    80002a24:	4509                	li	a0,2
    80002a26:	b761                	j	800029ae <devintr+0x1e>
      clockintr();
    80002a28:	00000097          	auipc	ra,0x0
    80002a2c:	f14080e7          	jalr	-236(ra) # 8000293c <clockintr>
    80002a30:	b7ed                	j	80002a1a <devintr+0x8a>

0000000080002a32 <usertrap>:
{
    80002a32:	1101                	addi	sp,sp,-32
    80002a34:	ec06                	sd	ra,24(sp)
    80002a36:	e822                	sd	s0,16(sp)
    80002a38:	e426                	sd	s1,8(sp)
    80002a3a:	e04a                	sd	s2,0(sp)
    80002a3c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3e:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a42:	1007f793          	andi	a5,a5,256
    80002a46:	e3b1                	bnez	a5,80002a8a <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a48:	00003797          	auipc	a5,0x3
    80002a4c:	4e878793          	addi	a5,a5,1256 # 80005f30 <kernelvec>
    80002a50:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f58080e7          	jalr	-168(ra) # 800019ac <myproc>
    80002a5c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a5e:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a60:	14102773          	csrr	a4,sepc
    80002a64:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a66:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a6a:	47a1                	li	a5,8
    80002a6c:	02f70763          	beq	a4,a5,80002a9a <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	f20080e7          	jalr	-224(ra) # 80002990 <devintr>
    80002a78:	892a                	mv	s2,a0
    80002a7a:	c92d                	beqz	a0,80002aec <usertrap+0xba>
  if (killed(p))
    80002a7c:	8526                	mv	a0,s1
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	91a080e7          	jalr	-1766(ra) # 80002398 <killed>
    80002a86:	c555                	beqz	a0,80002b32 <usertrap+0x100>
    80002a88:	a045                	j	80002b28 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	89650513          	addi	a0,a0,-1898 # 80008320 <states.0+0x58>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>
    if (killed(p))
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	8fe080e7          	jalr	-1794(ra) # 80002398 <killed>
    80002aa2:	ed1d                	bnez	a0,80002ae0 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002aa4:	70b8                	ld	a4,96(s1)
    80002aa6:	6f1c                	ld	a5,24(a4)
    80002aa8:	0791                	addi	a5,a5,4
    80002aaa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ab0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	3a2080e7          	jalr	930(ra) # 80002e5a <syscall>
  if (killed(p))
    80002ac0:	8526                	mv	a0,s1
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	8d6080e7          	jalr	-1834(ra) # 80002398 <killed>
    80002aca:	ed31                	bnez	a0,80002b26 <usertrap+0xf4>
  usertrapret();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	dda080e7          	jalr	-550(ra) # 800028a6 <usertrapret>
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6902                	ld	s2,0(sp)
    80002adc:	6105                	addi	sp,sp,32
    80002ade:	8082                	ret
      exit(-1);
    80002ae0:	557d                	li	a0,-1
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	736080e7          	jalr	1846(ra) # 80002218 <exit>
    80002aea:	bf6d                	j	80002aa4 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aec:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002af0:	5890                	lw	a2,48(s1)
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	84e50513          	addi	a0,a0,-1970 # 80008340 <states.0+0x78>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a8e080e7          	jalr	-1394(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b06:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	86650513          	addi	a0,a0,-1946 # 80008370 <states.0+0xa8>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
    setkilled(p);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	850080e7          	jalr	-1968(ra) # 8000236c <setkilled>
    80002b24:	bf71                	j	80002ac0 <usertrap+0x8e>
  if (killed(p))
    80002b26:	4901                	li	s2,0
    exit(-1);
    80002b28:	557d                	li	a0,-1
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	6ee080e7          	jalr	1774(ra) # 80002218 <exit>
  if (which_dev == 2){
    80002b32:	4789                	li	a5,2
    80002b34:	f8f91ce3          	bne	s2,a5,80002acc <usertrap+0x9a>
    if (which_dev == 2 && p->alarm == 0) {
    80002b38:	5cbc                	lw	a5,120(s1)
    80002b3a:	c791                	beqz	a5,80002b46 <usertrap+0x114>
    yield();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	56c080e7          	jalr	1388(ra) # 800020a8 <yield>
    80002b44:	b761                	j	80002acc <usertrap+0x9a>
    p->alarm = 1;
    80002b46:	4785                	li	a5,1
    80002b48:	dcbc                	sw	a5,120(s1)
    p->alram_tf=kalloc();
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	f9c080e7          	jalr	-100(ra) # 80000ae6 <kalloc>
    80002b52:	f8a8                	sd	a0,112(s1)
    memmove(p->alram_tf, p->trapframe, PGSIZE);
    80002b54:	6605                	lui	a2,0x1
    80002b56:	70ac                	ld	a1,96(s1)
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	1d6080e7          	jalr	470(ra) # 80000d2e <memmove>
    p->current_ticks++;
    80002b60:	54fc                	lw	a5,108(s1)
    80002b62:	2785                	addiw	a5,a5,1
    80002b64:	d4fc                	sw	a5,108(s1)
    if (p->current_ticks%p->ticks==0) {
    80002b66:	54b8                	lw	a4,104(s1)
    80002b68:	02e7e7bb          	remw	a5,a5,a4
    80002b6c:	fbe1                	bnez	a5,80002b3c <usertrap+0x10a>
        p->current_ticks=0;
    80002b6e:	0604a623          	sw	zero,108(s1)
        p->trapframe->epc = p->handler;
    80002b72:	70bc                	ld	a5,96(s1)
    80002b74:	68b8                	ld	a4,80(s1)
    80002b76:	ef98                	sd	a4,24(a5)
    80002b78:	b7d1                	j	80002b3c <usertrap+0x10a>

0000000080002b7a <kerneltrap>:
{
    80002b7a:	7179                	addi	sp,sp,-48
    80002b7c:	f406                	sd	ra,40(sp)
    80002b7e:	f022                	sd	s0,32(sp)
    80002b80:	ec26                	sd	s1,24(sp)
    80002b82:	e84a                	sd	s2,16(sp)
    80002b84:	e44e                	sd	s3,8(sp)
    80002b86:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b88:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b90:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b94:	1004f793          	andi	a5,s1,256
    80002b98:	cb85                	beqz	a5,80002bc8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b9e:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ba0:	ef85                	bnez	a5,80002bd8 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	dee080e7          	jalr	-530(ra) # 80002990 <devintr>
    80002baa:	cd1d                	beqz	a0,80002be8 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bac:	4789                	li	a5,2
    80002bae:	06f50a63          	beq	a0,a5,80002c22 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bb2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb6:	10049073          	csrw	sstatus,s1
}
    80002bba:	70a2                	ld	ra,40(sp)
    80002bbc:	7402                	ld	s0,32(sp)
    80002bbe:	64e2                	ld	s1,24(sp)
    80002bc0:	6942                	ld	s2,16(sp)
    80002bc2:	69a2                	ld	s3,8(sp)
    80002bc4:	6145                	addi	sp,sp,48
    80002bc6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bc8:	00005517          	auipc	a0,0x5
    80002bcc:	7c850513          	addi	a0,a0,1992 # 80008390 <states.0+0xc8>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002bd8:	00005517          	auipc	a0,0x5
    80002bdc:	7e050513          	addi	a0,a0,2016 # 800083b8 <states.0+0xf0>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002be8:	85ce                	mv	a1,s3
    80002bea:	00005517          	auipc	a0,0x5
    80002bee:	7ee50513          	addi	a0,a0,2030 # 800083d8 <states.0+0x110>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	996080e7          	jalr	-1642(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bfe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	7e650513          	addi	a0,a0,2022 # 800083e8 <states.0+0x120>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97e080e7          	jalr	-1666(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	7ee50513          	addi	a0,a0,2030 # 80008400 <states.0+0x138>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	d8a080e7          	jalr	-630(ra) # 800019ac <myproc>
    80002c2a:	d541                	beqz	a0,80002bb2 <kerneltrap+0x38>
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	d80080e7          	jalr	-640(ra) # 800019ac <myproc>
    80002c34:	4d18                	lw	a4,24(a0)
    80002c36:	4791                	li	a5,4
    80002c38:	f6f71de3          	bne	a4,a5,80002bb2 <kerneltrap+0x38>
    yield();
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	46c080e7          	jalr	1132(ra) # 800020a8 <yield>
    80002c44:	b7bd                	j	80002bb2 <kerneltrap+0x38>

0000000080002c46 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	1000                	addi	s0,sp,32
    80002c50:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	d5a080e7          	jalr	-678(ra) # 800019ac <myproc>
  switch (n) {
    80002c5a:	4795                	li	a5,5
    80002c5c:	0497e163          	bltu	a5,s1,80002c9e <argraw+0x58>
    80002c60:	048a                	slli	s1,s1,0x2
    80002c62:	00005717          	auipc	a4,0x5
    80002c66:	7d670713          	addi	a4,a4,2006 # 80008438 <states.0+0x170>
    80002c6a:	94ba                	add	s1,s1,a4
    80002c6c:	409c                	lw	a5,0(s1)
    80002c6e:	97ba                	add	a5,a5,a4
    80002c70:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c72:	713c                	ld	a5,96(a0)
    80002c74:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	64a2                	ld	s1,8(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret
    return p->trapframe->a1;
    80002c80:	713c                	ld	a5,96(a0)
    80002c82:	7fa8                	ld	a0,120(a5)
    80002c84:	bfcd                	j	80002c76 <argraw+0x30>
    return p->trapframe->a2;
    80002c86:	713c                	ld	a5,96(a0)
    80002c88:	63c8                	ld	a0,128(a5)
    80002c8a:	b7f5                	j	80002c76 <argraw+0x30>
    return p->trapframe->a3;
    80002c8c:	713c                	ld	a5,96(a0)
    80002c8e:	67c8                	ld	a0,136(a5)
    80002c90:	b7dd                	j	80002c76 <argraw+0x30>
    return p->trapframe->a4;
    80002c92:	713c                	ld	a5,96(a0)
    80002c94:	6bc8                	ld	a0,144(a5)
    80002c96:	b7c5                	j	80002c76 <argraw+0x30>
    return p->trapframe->a5;
    80002c98:	713c                	ld	a5,96(a0)
    80002c9a:	6fc8                	ld	a0,152(a5)
    80002c9c:	bfe9                	j	80002c76 <argraw+0x30>
  panic("argraw");
    80002c9e:	00005517          	auipc	a0,0x5
    80002ca2:	77250513          	addi	a0,a0,1906 # 80008410 <states.0+0x148>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	898080e7          	jalr	-1896(ra) # 8000053e <panic>

0000000080002cae <sys_sigreturn>:
  myproc()->ticks = ticks;

  return 0;
}
uint64 sys_sigreturn(void)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	cf4080e7          	jalr	-780(ra) # 800019ac <myproc>
    80002cc0:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alram_tf, PGSIZE);
    80002cc2:	6605                	lui	a2,0x1
    80002cc4:	792c                	ld	a1,112(a0)
    80002cc6:	7128                	ld	a0,96(a0)
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	066080e7          	jalr	102(ra) # 80000d2e <memmove>

  kfree(p->alram_tf);
    80002cd0:	78a8                	ld	a0,112(s1)
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	d18080e7          	jalr	-744(ra) # 800009ea <kfree>
  // p->alram_tf = 0;
  p->alarm = 0;
    80002cda:	0604ac23          	sw	zero,120(s1)
  p->current_ticks = 0;
    80002cde:	0604a623          	sw	zero,108(s1)
  usertrapret();
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	bc4080e7          	jalr	-1084(ra) # 800028a6 <usertrapret>
  return 0;
    80002cea:	4501                	li	a0,0
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret

0000000080002cf6 <fetchaddr>:
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	e04a                	sd	s2,0(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84aa                	mv	s1,a0
    80002d04:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	ca6080e7          	jalr	-858(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d0e:	653c                	ld	a5,72(a0)
    80002d10:	02f4f863          	bgeu	s1,a5,80002d40 <fetchaddr+0x4a>
    80002d14:	00848713          	addi	a4,s1,8
    80002d18:	02e7e663          	bltu	a5,a4,80002d44 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d1c:	46a1                	li	a3,8
    80002d1e:	8626                	mv	a2,s1
    80002d20:	85ca                	mv	a1,s2
    80002d22:	6d28                	ld	a0,88(a0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	9d0080e7          	jalr	-1584(ra) # 800016f4 <copyin>
    80002d2c:	00a03533          	snez	a0,a0
    80002d30:	40a00533          	neg	a0,a0
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6902                	ld	s2,0(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret
    return -1;
    80002d40:	557d                	li	a0,-1
    80002d42:	bfcd                	j	80002d34 <fetchaddr+0x3e>
    80002d44:	557d                	li	a0,-1
    80002d46:	b7fd                	j	80002d34 <fetchaddr+0x3e>

0000000080002d48 <fetchstr>:
{
    80002d48:	7179                	addi	sp,sp,-48
    80002d4a:	f406                	sd	ra,40(sp)
    80002d4c:	f022                	sd	s0,32(sp)
    80002d4e:	ec26                	sd	s1,24(sp)
    80002d50:	e84a                	sd	s2,16(sp)
    80002d52:	e44e                	sd	s3,8(sp)
    80002d54:	1800                	addi	s0,sp,48
    80002d56:	892a                	mv	s2,a0
    80002d58:	84ae                	mv	s1,a1
    80002d5a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	c50080e7          	jalr	-944(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d64:	86ce                	mv	a3,s3
    80002d66:	864a                	mv	a2,s2
    80002d68:	85a6                	mv	a1,s1
    80002d6a:	6d28                	ld	a0,88(a0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	a16080e7          	jalr	-1514(ra) # 80001782 <copyinstr>
    80002d74:	00054e63          	bltz	a0,80002d90 <fetchstr+0x48>
  return strlen(buf);
    80002d78:	8526                	mv	a0,s1
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	0d4080e7          	jalr	212(ra) # 80000e4e <strlen>
}
    80002d82:	70a2                	ld	ra,40(sp)
    80002d84:	7402                	ld	s0,32(sp)
    80002d86:	64e2                	ld	s1,24(sp)
    80002d88:	6942                	ld	s2,16(sp)
    80002d8a:	69a2                	ld	s3,8(sp)
    80002d8c:	6145                	addi	sp,sp,48
    80002d8e:	8082                	ret
    return -1;
    80002d90:	557d                	li	a0,-1
    80002d92:	bfc5                	j	80002d82 <fetchstr+0x3a>

0000000080002d94 <argint>:
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	1000                	addi	s0,sp,32
    80002d9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ea6080e7          	jalr	-346(ra) # 80002c46 <argraw>
    80002da8:	c088                	sw	a0,0(s1)
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	64a2                	ld	s1,8(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret

0000000080002db4 <argaddr>:
{
    80002db4:	1101                	addi	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	e426                	sd	s1,8(sp)
    80002dbc:	1000                	addi	s0,sp,32
    80002dbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	e86080e7          	jalr	-378(ra) # 80002c46 <argraw>
    80002dc8:	e088                	sd	a0,0(s1)
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_sigalarm>:
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	1800                	addi	s0,sp,48
    80002ddc:	fca42e23          	sw	a0,-36(s0)
  argint(0,&ticks);
    80002de0:	fdc40593          	addi	a1,s0,-36
    80002de4:	4501                	li	a0,0
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	fae080e7          	jalr	-82(ra) # 80002d94 <argint>
  argaddr(1,&addr);
    80002dee:	fe840593          	addi	a1,s0,-24
    80002df2:	4505                	li	a0,1
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	fc0080e7          	jalr	-64(ra) # 80002db4 <argaddr>
  myproc()->handler = addr;
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	bb0080e7          	jalr	-1104(ra) # 800019ac <myproc>
    80002e04:	fe843783          	ld	a5,-24(s0)
    80002e08:	e93c                	sd	a5,80(a0)
  myproc()->ticks = ticks;
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	ba2080e7          	jalr	-1118(ra) # 800019ac <myproc>
    80002e12:	fdc42783          	lw	a5,-36(s0)
    80002e16:	d53c                	sw	a5,104(a0)
}
    80002e18:	4501                	li	a0,0
    80002e1a:	70a2                	ld	ra,40(sp)
    80002e1c:	7402                	ld	s0,32(sp)
    80002e1e:	6145                	addi	sp,sp,48
    80002e20:	8082                	ret

0000000080002e22 <argstr>:
{
    80002e22:	7179                	addi	sp,sp,-48
    80002e24:	f406                	sd	ra,40(sp)
    80002e26:	f022                	sd	s0,32(sp)
    80002e28:	ec26                	sd	s1,24(sp)
    80002e2a:	e84a                	sd	s2,16(sp)
    80002e2c:	1800                	addi	s0,sp,48
    80002e2e:	84ae                	mv	s1,a1
    80002e30:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002e32:	fd840593          	addi	a1,s0,-40
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	f7e080e7          	jalr	-130(ra) # 80002db4 <argaddr>
  return fetchstr(addr, buf, max);
    80002e3e:	864a                	mv	a2,s2
    80002e40:	85a6                	mv	a1,s1
    80002e42:	fd843503          	ld	a0,-40(s0)
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	f02080e7          	jalr	-254(ra) # 80002d48 <fetchstr>
}
    80002e4e:	70a2                	ld	ra,40(sp)
    80002e50:	7402                	ld	s0,32(sp)
    80002e52:	64e2                	ld	s1,24(sp)
    80002e54:	6942                	ld	s2,16(sp)
    80002e56:	6145                	addi	sp,sp,48
    80002e58:	8082                	ret

0000000080002e5a <syscall>:
{
    80002e5a:	1101                	addi	sp,sp,-32
    80002e5c:	ec06                	sd	ra,24(sp)
    80002e5e:	e822                	sd	s0,16(sp)
    80002e60:	e426                	sd	s1,8(sp)
    80002e62:	e04a                	sd	s2,0(sp)
    80002e64:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	b46080e7          	jalr	-1210(ra) # 800019ac <myproc>
    80002e6e:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002e70:	06053903          	ld	s2,96(a0)
    80002e74:	0a893783          	ld	a5,168(s2)
    80002e78:	0007869b          	sext.w	a3,a5
  if(num==SYS_read){
    80002e7c:	4715                	li	a4,5
    80002e7e:	02e68663          	beq	a3,a4,80002eaa <syscall+0x50>
  if(num==SYS_getreadcount){
    80002e82:	475d                	li	a4,23
    80002e84:	04e69663          	bne	a3,a4,80002ed0 <syscall+0x76>
    p->readcount=readcountvalue;
    80002e88:	00006717          	auipc	a4,0x6
    80002e8c:	a5c72703          	lw	a4,-1444(a4) # 800088e4 <readcountvalue>
    80002e90:	d958                	sw	a4,52(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e92:	37fd                	addiw	a5,a5,-1
    80002e94:	4661                	li	a2,24
    80002e96:	00000717          	auipc	a4,0x0
    80002e9a:	2f870713          	addi	a4,a4,760 # 8000318e <sys_getreadcount>
    80002e9e:	04f66663          	bltu	a2,a5,80002eea <syscall+0x90>
    p->trapframe->a0 = syscalls[num]();
    80002ea2:	9702                	jalr	a4
    80002ea4:	06a93823          	sd	a0,112(s2)
    80002ea8:	a8b9                	j	80002f06 <syscall+0xac>
    readcountvalue++;
    80002eaa:	00006617          	auipc	a2,0x6
    80002eae:	a3a60613          	addi	a2,a2,-1478 # 800088e4 <readcountvalue>
    80002eb2:	4218                	lw	a4,0(a2)
    80002eb4:	2705                	addiw	a4,a4,1
    80002eb6:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eb8:	37fd                	addiw	a5,a5,-1
    80002eba:	4761                	li	a4,24
    80002ebc:	02f76763          	bltu	a4,a5,80002eea <syscall+0x90>
    80002ec0:	068e                	slli	a3,a3,0x3
    80002ec2:	00005797          	auipc	a5,0x5
    80002ec6:	58e78793          	addi	a5,a5,1422 # 80008450 <syscalls>
    80002eca:	96be                	add	a3,a3,a5
    80002ecc:	6298                	ld	a4,0(a3)
    80002ece:	bfd1                	j	80002ea2 <syscall+0x48>
    80002ed0:	37fd                	addiw	a5,a5,-1
    80002ed2:	4761                	li	a4,24
    80002ed4:	00f76b63          	bltu	a4,a5,80002eea <syscall+0x90>
    80002ed8:	00369713          	slli	a4,a3,0x3
    80002edc:	00005797          	auipc	a5,0x5
    80002ee0:	57478793          	addi	a5,a5,1396 # 80008450 <syscalls>
    80002ee4:	97ba                	add	a5,a5,a4
    80002ee6:	6398                	ld	a4,0(a5)
    80002ee8:	ff4d                	bnez	a4,80002ea2 <syscall+0x48>
    printf("%d %s: unknown sys call %d\n",
    80002eea:	17848613          	addi	a2,s1,376
    80002eee:	588c                	lw	a1,48(s1)
    80002ef0:	00005517          	auipc	a0,0x5
    80002ef4:	52850513          	addi	a0,a0,1320 # 80008418 <states.0+0x150>
    80002ef8:	ffffd097          	auipc	ra,0xffffd
    80002efc:	690080e7          	jalr	1680(ra) # 80000588 <printf>
    p->trapframe->a0 = -1;
    80002f00:	70bc                	ld	a5,96(s1)
    80002f02:	577d                	li	a4,-1
    80002f04:	fbb8                	sd	a4,112(a5)
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	64a2                	ld	s1,8(sp)
    80002f0c:	6902                	ld	s2,0(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f1a:	fec40593          	addi	a1,s0,-20
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	e74080e7          	jalr	-396(ra) # 80002d94 <argint>
  exit(n);
    80002f28:	fec42503          	lw	a0,-20(s0)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	2ec080e7          	jalr	748(ra) # 80002218 <exit>
  return 0; // not reached
}
    80002f34:	4501                	li	a0,0
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f3e:	1141                	addi	sp,sp,-16
    80002f40:	e406                	sd	ra,8(sp)
    80002f42:	e022                	sd	s0,0(sp)
    80002f44:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	a66080e7          	jalr	-1434(ra) # 800019ac <myproc>
}
    80002f4e:	5908                	lw	a0,48(a0)
    80002f50:	60a2                	ld	ra,8(sp)
    80002f52:	6402                	ld	s0,0(sp)
    80002f54:	0141                	addi	sp,sp,16
    80002f56:	8082                	ret

0000000080002f58 <sys_fork>:

uint64
sys_fork(void)
{
    80002f58:	1141                	addi	sp,sp,-16
    80002f5a:	e406                	sd	ra,8(sp)
    80002f5c:	e022                	sd	s0,0(sp)
    80002f5e:	0800                	addi	s0,sp,16
  return fork();
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	e36080e7          	jalr	-458(ra) # 80001d96 <fork>
}
    80002f68:	60a2                	ld	ra,8(sp)
    80002f6a:	6402                	ld	s0,0(sp)
    80002f6c:	0141                	addi	sp,sp,16
    80002f6e:	8082                	ret

0000000080002f70 <sys_wait>:

uint64
sys_wait(void)
{
    80002f70:	1101                	addi	sp,sp,-32
    80002f72:	ec06                	sd	ra,24(sp)
    80002f74:	e822                	sd	s0,16(sp)
    80002f76:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f78:	fe840593          	addi	a1,s0,-24
    80002f7c:	4501                	li	a0,0
    80002f7e:	00000097          	auipc	ra,0x0
    80002f82:	e36080e7          	jalr	-458(ra) # 80002db4 <argaddr>
  return wait(p);
    80002f86:	fe843503          	ld	a0,-24(s0)
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	440080e7          	jalr	1088(ra) # 800023ca <wait>
}
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002fa4:	fdc40593          	addi	a1,s0,-36
    80002fa8:	4501                	li	a0,0
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	dea080e7          	jalr	-534(ra) # 80002d94 <argint>
  addr = myproc()->sz;
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	9fa080e7          	jalr	-1542(ra) # 800019ac <myproc>
    80002fba:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002fbc:	fdc42503          	lw	a0,-36(s0)
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	d7a080e7          	jalr	-646(ra) # 80001d3a <growproc>
    80002fc8:	00054863          	bltz	a0,80002fd8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fcc:	8526                	mv	a0,s1
    80002fce:	70a2                	ld	ra,40(sp)
    80002fd0:	7402                	ld	s0,32(sp)
    80002fd2:	64e2                	ld	s1,24(sp)
    80002fd4:	6145                	addi	sp,sp,48
    80002fd6:	8082                	ret
    return -1;
    80002fd8:	54fd                	li	s1,-1
    80002fda:	bfcd                	j	80002fcc <sys_sbrk+0x32>

0000000080002fdc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fdc:	7139                	addi	sp,sp,-64
    80002fde:	fc06                	sd	ra,56(sp)
    80002fe0:	f822                	sd	s0,48(sp)
    80002fe2:	f426                	sd	s1,40(sp)
    80002fe4:	f04a                	sd	s2,32(sp)
    80002fe6:	ec4e                	sd	s3,24(sp)
    80002fe8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fea:	fcc40593          	addi	a1,s0,-52
    80002fee:	4501                	li	a0,0
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	da4080e7          	jalr	-604(ra) # 80002d94 <argint>
  acquire(&tickslock);
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	58850513          	addi	a0,a0,1416 # 80017580 <tickslock>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	bd6080e7          	jalr	-1066(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003008:	00006917          	auipc	s2,0x6
    8000300c:	8d892903          	lw	s2,-1832(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80003010:	fcc42783          	lw	a5,-52(s0)
    80003014:	cf9d                	beqz	a5,80003052 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003016:	00014997          	auipc	s3,0x14
    8000301a:	56a98993          	addi	s3,s3,1386 # 80017580 <tickslock>
    8000301e:	00006497          	auipc	s1,0x6
    80003022:	8c248493          	addi	s1,s1,-1854 # 800088e0 <ticks>
    if (killed(myproc()))
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	986080e7          	jalr	-1658(ra) # 800019ac <myproc>
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	36a080e7          	jalr	874(ra) # 80002398 <killed>
    80003036:	ed15                	bnez	a0,80003072 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003038:	85ce                	mv	a1,s3
    8000303a:	8526                	mv	a0,s1
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	0a8080e7          	jalr	168(ra) # 800020e4 <sleep>
  while (ticks - ticks0 < n)
    80003044:	409c                	lw	a5,0(s1)
    80003046:	412787bb          	subw	a5,a5,s2
    8000304a:	fcc42703          	lw	a4,-52(s0)
    8000304e:	fce7ece3          	bltu	a5,a4,80003026 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003052:	00014517          	auipc	a0,0x14
    80003056:	52e50513          	addi	a0,a0,1326 # 80017580 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c30080e7          	jalr	-976(ra) # 80000c8a <release>
  return 0;
    80003062:	4501                	li	a0,0
}
    80003064:	70e2                	ld	ra,56(sp)
    80003066:	7442                	ld	s0,48(sp)
    80003068:	74a2                	ld	s1,40(sp)
    8000306a:	7902                	ld	s2,32(sp)
    8000306c:	69e2                	ld	s3,24(sp)
    8000306e:	6121                	addi	sp,sp,64
    80003070:	8082                	ret
      release(&tickslock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	50e50513          	addi	a0,a0,1294 # 80017580 <tickslock>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>
      return -1;
    80003082:	557d                	li	a0,-1
    80003084:	b7c5                	j	80003064 <sys_sleep+0x88>

0000000080003086 <sys_kill>:

uint64
sys_kill(void)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000308e:	fec40593          	addi	a1,s0,-20
    80003092:	4501                	li	a0,0
    80003094:	00000097          	auipc	ra,0x0
    80003098:	d00080e7          	jalr	-768(ra) # 80002d94 <argint>
  return kill(pid);
    8000309c:	fec42503          	lw	a0,-20(s0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	25a080e7          	jalr	602(ra) # 800022fa <kill>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	e426                	sd	s1,8(sp)
    800030b8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ba:	00014517          	auipc	a0,0x14
    800030be:	4c650513          	addi	a0,a0,1222 # 80017580 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	b14080e7          	jalr	-1260(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030ca:	00006497          	auipc	s1,0x6
    800030ce:	8164a483          	lw	s1,-2026(s1) # 800088e0 <ticks>
  release(&tickslock);
    800030d2:	00014517          	auipc	a0,0x14
    800030d6:	4ae50513          	addi	a0,a0,1198 # 80017580 <tickslock>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bb0080e7          	jalr	-1104(ra) # 80000c8a <release>
  return xticks;
}
    800030e2:	02049513          	slli	a0,s1,0x20
    800030e6:	9101                	srli	a0,a0,0x20
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800030f2:	7139                	addi	sp,sp,-64
    800030f4:	fc06                	sd	ra,56(sp)
    800030f6:	f822                	sd	s0,48(sp)
    800030f8:	f426                	sd	s1,40(sp)
    800030fa:	f04a                	sd	s2,32(sp)
    800030fc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030fe:	fd840593          	addi	a1,s0,-40
    80003102:	4501                	li	a0,0
    80003104:	00000097          	auipc	ra,0x0
    80003108:	cb0080e7          	jalr	-848(ra) # 80002db4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000310c:	fd040593          	addi	a1,s0,-48
    80003110:	4505                	li	a0,1
    80003112:	00000097          	auipc	ra,0x0
    80003116:	ca2080e7          	jalr	-862(ra) # 80002db4 <argaddr>
  argaddr(2, &addr2);
    8000311a:	fc840593          	addi	a1,s0,-56
    8000311e:	4509                	li	a0,2
    80003120:	00000097          	auipc	ra,0x0
    80003124:	c94080e7          	jalr	-876(ra) # 80002db4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003128:	fc040613          	addi	a2,s0,-64
    8000312c:	fc440593          	addi	a1,s0,-60
    80003130:	fd843503          	ld	a0,-40(s0)
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	51e080e7          	jalr	1310(ra) # 80002652 <waitx>
    8000313c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000313e:	fffff097          	auipc	ra,0xfffff
    80003142:	86e080e7          	jalr	-1938(ra) # 800019ac <myproc>
    80003146:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003148:	4691                	li	a3,4
    8000314a:	fc440613          	addi	a2,s0,-60
    8000314e:	fd043583          	ld	a1,-48(s0)
    80003152:	6d28                	ld	a0,88(a0)
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	514080e7          	jalr	1300(ra) # 80001668 <copyout>
    return -1;
    8000315c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000315e:	00054f63          	bltz	a0,8000317c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003162:	4691                	li	a3,4
    80003164:	fc040613          	addi	a2,s0,-64
    80003168:	fc843583          	ld	a1,-56(s0)
    8000316c:	6ca8                	ld	a0,88(s1)
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	4fa080e7          	jalr	1274(ra) # 80001668 <copyout>
    80003176:	00054a63          	bltz	a0,8000318a <sys_waitx+0x98>
    return -1;
  return ret;
    8000317a:	87ca                	mv	a5,s2
}
    8000317c:	853e                	mv	a0,a5
    8000317e:	70e2                	ld	ra,56(sp)
    80003180:	7442                	ld	s0,48(sp)
    80003182:	74a2                	ld	s1,40(sp)
    80003184:	7902                	ld	s2,32(sp)
    80003186:	6121                	addi	sp,sp,64
    80003188:	8082                	ret
    return -1;
    8000318a:	57fd                	li	a5,-1
    8000318c:	bfc5                	j	8000317c <sys_waitx+0x8a>

000000008000318e <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    8000318e:	1141                	addi	sp,sp,-16
    80003190:	e406                	sd	ra,8(sp)
    80003192:	e022                	sd	s0,0(sp)
    80003194:	0800                	addi	s0,sp,16
  return myproc()->readcount;
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	816080e7          	jalr	-2026(ra) # 800019ac <myproc>
}
    8000319e:	5948                	lw	a0,52(a0)
    800031a0:	60a2                	ld	ra,8(sp)
    800031a2:	6402                	ld	s0,0(sp)
    800031a4:	0141                	addi	sp,sp,16
    800031a6:	8082                	ret

00000000800031a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031a8:	7179                	addi	sp,sp,-48
    800031aa:	f406                	sd	ra,40(sp)
    800031ac:	f022                	sd	s0,32(sp)
    800031ae:	ec26                	sd	s1,24(sp)
    800031b0:	e84a                	sd	s2,16(sp)
    800031b2:	e44e                	sd	s3,8(sp)
    800031b4:	e052                	sd	s4,0(sp)
    800031b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031b8:	00005597          	auipc	a1,0x5
    800031bc:	36858593          	addi	a1,a1,872 # 80008520 <syscalls+0xd0>
    800031c0:	00014517          	auipc	a0,0x14
    800031c4:	3d850513          	addi	a0,a0,984 # 80017598 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	97e080e7          	jalr	-1666(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031d0:	0001c797          	auipc	a5,0x1c
    800031d4:	3c878793          	addi	a5,a5,968 # 8001f598 <bcache+0x8000>
    800031d8:	0001c717          	auipc	a4,0x1c
    800031dc:	62870713          	addi	a4,a4,1576 # 8001f800 <bcache+0x8268>
    800031e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031e8:	00014497          	auipc	s1,0x14
    800031ec:	3c848493          	addi	s1,s1,968 # 800175b0 <bcache+0x18>
    b->next = bcache.head.next;
    800031f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031f4:	00005a17          	auipc	s4,0x5
    800031f8:	334a0a13          	addi	s4,s4,820 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031fc:	2b893783          	ld	a5,696(s2)
    80003200:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003202:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003206:	85d2                	mv	a1,s4
    80003208:	01048513          	addi	a0,s1,16
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	4c4080e7          	jalr	1220(ra) # 800046d0 <initsleeplock>
    bcache.head.next->prev = b;
    80003214:	2b893783          	ld	a5,696(s2)
    80003218:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000321a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000321e:	45848493          	addi	s1,s1,1112
    80003222:	fd349de3          	bne	s1,s3,800031fc <binit+0x54>
  }
}
    80003226:	70a2                	ld	ra,40(sp)
    80003228:	7402                	ld	s0,32(sp)
    8000322a:	64e2                	ld	s1,24(sp)
    8000322c:	6942                	ld	s2,16(sp)
    8000322e:	69a2                	ld	s3,8(sp)
    80003230:	6a02                	ld	s4,0(sp)
    80003232:	6145                	addi	sp,sp,48
    80003234:	8082                	ret

0000000080003236 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003236:	7179                	addi	sp,sp,-48
    80003238:	f406                	sd	ra,40(sp)
    8000323a:	f022                	sd	s0,32(sp)
    8000323c:	ec26                	sd	s1,24(sp)
    8000323e:	e84a                	sd	s2,16(sp)
    80003240:	e44e                	sd	s3,8(sp)
    80003242:	1800                	addi	s0,sp,48
    80003244:	892a                	mv	s2,a0
    80003246:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003248:	00014517          	auipc	a0,0x14
    8000324c:	35050513          	addi	a0,a0,848 # 80017598 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	986080e7          	jalr	-1658(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003258:	0001c497          	auipc	s1,0x1c
    8000325c:	5f84b483          	ld	s1,1528(s1) # 8001f850 <bcache+0x82b8>
    80003260:	0001c797          	auipc	a5,0x1c
    80003264:	5a078793          	addi	a5,a5,1440 # 8001f800 <bcache+0x8268>
    80003268:	02f48f63          	beq	s1,a5,800032a6 <bread+0x70>
    8000326c:	873e                	mv	a4,a5
    8000326e:	a021                	j	80003276 <bread+0x40>
    80003270:	68a4                	ld	s1,80(s1)
    80003272:	02e48a63          	beq	s1,a4,800032a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003276:	449c                	lw	a5,8(s1)
    80003278:	ff279ce3          	bne	a5,s2,80003270 <bread+0x3a>
    8000327c:	44dc                	lw	a5,12(s1)
    8000327e:	ff3799e3          	bne	a5,s3,80003270 <bread+0x3a>
      b->refcnt++;
    80003282:	40bc                	lw	a5,64(s1)
    80003284:	2785                	addiw	a5,a5,1
    80003286:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003288:	00014517          	auipc	a0,0x14
    8000328c:	31050513          	addi	a0,a0,784 # 80017598 <bcache>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003298:	01048513          	addi	a0,s1,16
    8000329c:	00001097          	auipc	ra,0x1
    800032a0:	46e080e7          	jalr	1134(ra) # 8000470a <acquiresleep>
      return b;
    800032a4:	a8b9                	j	80003302 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032a6:	0001c497          	auipc	s1,0x1c
    800032aa:	5a24b483          	ld	s1,1442(s1) # 8001f848 <bcache+0x82b0>
    800032ae:	0001c797          	auipc	a5,0x1c
    800032b2:	55278793          	addi	a5,a5,1362 # 8001f800 <bcache+0x8268>
    800032b6:	00f48863          	beq	s1,a5,800032c6 <bread+0x90>
    800032ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032bc:	40bc                	lw	a5,64(s1)
    800032be:	cf81                	beqz	a5,800032d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c0:	64a4                	ld	s1,72(s1)
    800032c2:	fee49de3          	bne	s1,a4,800032bc <bread+0x86>
  panic("bget: no buffers");
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	26a50513          	addi	a0,a0,618 # 80008530 <syscalls+0xe0>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
      b->dev = dev;
    800032d6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032da:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032e2:	4785                	li	a5,1
    800032e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	2b250513          	addi	a0,a0,690 # 80017598 <bcache>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	99c080e7          	jalr	-1636(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032f6:	01048513          	addi	a0,s1,16
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	410080e7          	jalr	1040(ra) # 8000470a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003302:	409c                	lw	a5,0(s1)
    80003304:	cb89                	beqz	a5,80003316 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003306:	8526                	mv	a0,s1
    80003308:	70a2                	ld	ra,40(sp)
    8000330a:	7402                	ld	s0,32(sp)
    8000330c:	64e2                	ld	s1,24(sp)
    8000330e:	6942                	ld	s2,16(sp)
    80003310:	69a2                	ld	s3,8(sp)
    80003312:	6145                	addi	sp,sp,48
    80003314:	8082                	ret
    virtio_disk_rw(b, 0);
    80003316:	4581                	li	a1,0
    80003318:	8526                	mv	a0,s1
    8000331a:	00003097          	auipc	ra,0x3
    8000331e:	fda080e7          	jalr	-38(ra) # 800062f4 <virtio_disk_rw>
    b->valid = 1;
    80003322:	4785                	li	a5,1
    80003324:	c09c                	sw	a5,0(s1)
  return b;
    80003326:	b7c5                	j	80003306 <bread+0xd0>

0000000080003328 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	e426                	sd	s1,8(sp)
    80003330:	1000                	addi	s0,sp,32
    80003332:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003334:	0541                	addi	a0,a0,16
    80003336:	00001097          	auipc	ra,0x1
    8000333a:	46e080e7          	jalr	1134(ra) # 800047a4 <holdingsleep>
    8000333e:	cd01                	beqz	a0,80003356 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003340:	4585                	li	a1,1
    80003342:	8526                	mv	a0,s1
    80003344:	00003097          	auipc	ra,0x3
    80003348:	fb0080e7          	jalr	-80(ra) # 800062f4 <virtio_disk_rw>
}
    8000334c:	60e2                	ld	ra,24(sp)
    8000334e:	6442                	ld	s0,16(sp)
    80003350:	64a2                	ld	s1,8(sp)
    80003352:	6105                	addi	sp,sp,32
    80003354:	8082                	ret
    panic("bwrite");
    80003356:	00005517          	auipc	a0,0x5
    8000335a:	1f250513          	addi	a0,a0,498 # 80008548 <syscalls+0xf8>
    8000335e:	ffffd097          	auipc	ra,0xffffd
    80003362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080003366 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003366:	1101                	addi	sp,sp,-32
    80003368:	ec06                	sd	ra,24(sp)
    8000336a:	e822                	sd	s0,16(sp)
    8000336c:	e426                	sd	s1,8(sp)
    8000336e:	e04a                	sd	s2,0(sp)
    80003370:	1000                	addi	s0,sp,32
    80003372:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003374:	01050913          	addi	s2,a0,16
    80003378:	854a                	mv	a0,s2
    8000337a:	00001097          	auipc	ra,0x1
    8000337e:	42a080e7          	jalr	1066(ra) # 800047a4 <holdingsleep>
    80003382:	c92d                	beqz	a0,800033f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003384:	854a                	mv	a0,s2
    80003386:	00001097          	auipc	ra,0x1
    8000338a:	3da080e7          	jalr	986(ra) # 80004760 <releasesleep>

  acquire(&bcache.lock);
    8000338e:	00014517          	auipc	a0,0x14
    80003392:	20a50513          	addi	a0,a0,522 # 80017598 <bcache>
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	840080e7          	jalr	-1984(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000339e:	40bc                	lw	a5,64(s1)
    800033a0:	37fd                	addiw	a5,a5,-1
    800033a2:	0007871b          	sext.w	a4,a5
    800033a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033a8:	eb05                	bnez	a4,800033d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033aa:	68bc                	ld	a5,80(s1)
    800033ac:	64b8                	ld	a4,72(s1)
    800033ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033b0:	64bc                	ld	a5,72(s1)
    800033b2:	68b8                	ld	a4,80(s1)
    800033b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033b6:	0001c797          	auipc	a5,0x1c
    800033ba:	1e278793          	addi	a5,a5,482 # 8001f598 <bcache+0x8000>
    800033be:	2b87b703          	ld	a4,696(a5)
    800033c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033c4:	0001c717          	auipc	a4,0x1c
    800033c8:	43c70713          	addi	a4,a4,1084 # 8001f800 <bcache+0x8268>
    800033cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033ce:	2b87b703          	ld	a4,696(a5)
    800033d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033d8:	00014517          	auipc	a0,0x14
    800033dc:	1c050513          	addi	a0,a0,448 # 80017598 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6902                	ld	s2,0(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret
    panic("brelse");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	15c50513          	addi	a0,a0,348 # 80008550 <syscalls+0x100>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	142080e7          	jalr	322(ra) # 8000053e <panic>

0000000080003404 <bpin>:

void
bpin(struct buf *b) {
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	1000                	addi	s0,sp,32
    8000340e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003410:	00014517          	auipc	a0,0x14
    80003414:	18850513          	addi	a0,a0,392 # 80017598 <bcache>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003420:	40bc                	lw	a5,64(s1)
    80003422:	2785                	addiw	a5,a5,1
    80003424:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003426:	00014517          	auipc	a0,0x14
    8000342a:	17250513          	addi	a0,a0,370 # 80017598 <bcache>
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
}
    80003436:	60e2                	ld	ra,24(sp)
    80003438:	6442                	ld	s0,16(sp)
    8000343a:	64a2                	ld	s1,8(sp)
    8000343c:	6105                	addi	sp,sp,32
    8000343e:	8082                	ret

0000000080003440 <bunpin>:

void
bunpin(struct buf *b) {
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000344c:	00014517          	auipc	a0,0x14
    80003450:	14c50513          	addi	a0,a0,332 # 80017598 <bcache>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	782080e7          	jalr	1922(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000345c:	40bc                	lw	a5,64(s1)
    8000345e:	37fd                	addiw	a5,a5,-1
    80003460:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003462:	00014517          	auipc	a0,0x14
    80003466:	13650513          	addi	a0,a0,310 # 80017598 <bcache>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	820080e7          	jalr	-2016(ra) # 80000c8a <release>
}
    80003472:	60e2                	ld	ra,24(sp)
    80003474:	6442                	ld	s0,16(sp)
    80003476:	64a2                	ld	s1,8(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret

000000008000347c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	e04a                	sd	s2,0(sp)
    80003486:	1000                	addi	s0,sp,32
    80003488:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000348a:	00d5d59b          	srliw	a1,a1,0xd
    8000348e:	0001c797          	auipc	a5,0x1c
    80003492:	7e67a783          	lw	a5,2022(a5) # 8001fc74 <sb+0x1c>
    80003496:	9dbd                	addw	a1,a1,a5
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	d9e080e7          	jalr	-610(ra) # 80003236 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034a0:	0074f713          	andi	a4,s1,7
    800034a4:	4785                	li	a5,1
    800034a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034aa:	14ce                	slli	s1,s1,0x33
    800034ac:	90d9                	srli	s1,s1,0x36
    800034ae:	00950733          	add	a4,a0,s1
    800034b2:	05874703          	lbu	a4,88(a4)
    800034b6:	00e7f6b3          	and	a3,a5,a4
    800034ba:	c69d                	beqz	a3,800034e8 <bfree+0x6c>
    800034bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034be:	94aa                	add	s1,s1,a0
    800034c0:	fff7c793          	not	a5,a5
    800034c4:	8ff9                	and	a5,a5,a4
    800034c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	120080e7          	jalr	288(ra) # 800045ea <log_write>
  brelse(bp);
    800034d2:	854a                	mv	a0,s2
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	e92080e7          	jalr	-366(ra) # 80003366 <brelse>
}
    800034dc:	60e2                	ld	ra,24(sp)
    800034de:	6442                	ld	s0,16(sp)
    800034e0:	64a2                	ld	s1,8(sp)
    800034e2:	6902                	ld	s2,0(sp)
    800034e4:	6105                	addi	sp,sp,32
    800034e6:	8082                	ret
    panic("freeing free block");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	07050513          	addi	a0,a0,112 # 80008558 <syscalls+0x108>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800034f8 <balloc>:
{
    800034f8:	711d                	addi	sp,sp,-96
    800034fa:	ec86                	sd	ra,88(sp)
    800034fc:	e8a2                	sd	s0,80(sp)
    800034fe:	e4a6                	sd	s1,72(sp)
    80003500:	e0ca                	sd	s2,64(sp)
    80003502:	fc4e                	sd	s3,56(sp)
    80003504:	f852                	sd	s4,48(sp)
    80003506:	f456                	sd	s5,40(sp)
    80003508:	f05a                	sd	s6,32(sp)
    8000350a:	ec5e                	sd	s7,24(sp)
    8000350c:	e862                	sd	s8,16(sp)
    8000350e:	e466                	sd	s9,8(sp)
    80003510:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003512:	0001c797          	auipc	a5,0x1c
    80003516:	74a7a783          	lw	a5,1866(a5) # 8001fc5c <sb+0x4>
    8000351a:	10078163          	beqz	a5,8000361c <balloc+0x124>
    8000351e:	8baa                	mv	s7,a0
    80003520:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003522:	0001cb17          	auipc	s6,0x1c
    80003526:	736b0b13          	addi	s6,s6,1846 # 8001fc58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000352c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003530:	6c89                	lui	s9,0x2
    80003532:	a061                	j	800035ba <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003534:	974a                	add	a4,a4,s2
    80003536:	8fd5                	or	a5,a5,a3
    80003538:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	0ac080e7          	jalr	172(ra) # 800045ea <log_write>
        brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	e1e080e7          	jalr	-482(ra) # 80003366 <brelse>
  bp = bread(dev, bno);
    80003550:	85a6                	mv	a1,s1
    80003552:	855e                	mv	a0,s7
    80003554:	00000097          	auipc	ra,0x0
    80003558:	ce2080e7          	jalr	-798(ra) # 80003236 <bread>
    8000355c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000355e:	40000613          	li	a2,1024
    80003562:	4581                	li	a1,0
    80003564:	05850513          	addi	a0,a0,88
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	76a080e7          	jalr	1898(ra) # 80000cd2 <memset>
  log_write(bp);
    80003570:	854a                	mv	a0,s2
    80003572:	00001097          	auipc	ra,0x1
    80003576:	078080e7          	jalr	120(ra) # 800045ea <log_write>
  brelse(bp);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	dea080e7          	jalr	-534(ra) # 80003366 <brelse>
}
    80003584:	8526                	mv	a0,s1
    80003586:	60e6                	ld	ra,88(sp)
    80003588:	6446                	ld	s0,80(sp)
    8000358a:	64a6                	ld	s1,72(sp)
    8000358c:	6906                	ld	s2,64(sp)
    8000358e:	79e2                	ld	s3,56(sp)
    80003590:	7a42                	ld	s4,48(sp)
    80003592:	7aa2                	ld	s5,40(sp)
    80003594:	7b02                	ld	s6,32(sp)
    80003596:	6be2                	ld	s7,24(sp)
    80003598:	6c42                	ld	s8,16(sp)
    8000359a:	6ca2                	ld	s9,8(sp)
    8000359c:	6125                	addi	sp,sp,96
    8000359e:	8082                	ret
    brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	dc4080e7          	jalr	-572(ra) # 80003366 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035aa:	015c87bb          	addw	a5,s9,s5
    800035ae:	00078a9b          	sext.w	s5,a5
    800035b2:	004b2703          	lw	a4,4(s6)
    800035b6:	06eaf363          	bgeu	s5,a4,8000361c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800035ba:	41fad79b          	sraiw	a5,s5,0x1f
    800035be:	0137d79b          	srliw	a5,a5,0x13
    800035c2:	015787bb          	addw	a5,a5,s5
    800035c6:	40d7d79b          	sraiw	a5,a5,0xd
    800035ca:	01cb2583          	lw	a1,28(s6)
    800035ce:	9dbd                	addw	a1,a1,a5
    800035d0:	855e                	mv	a0,s7
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	c64080e7          	jalr	-924(ra) # 80003236 <bread>
    800035da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035dc:	004b2503          	lw	a0,4(s6)
    800035e0:	000a849b          	sext.w	s1,s5
    800035e4:	8662                	mv	a2,s8
    800035e6:	faa4fde3          	bgeu	s1,a0,800035a0 <balloc+0xa8>
      m = 1 << (bi % 8);
    800035ea:	41f6579b          	sraiw	a5,a2,0x1f
    800035ee:	01d7d69b          	srliw	a3,a5,0x1d
    800035f2:	00c6873b          	addw	a4,a3,a2
    800035f6:	00777793          	andi	a5,a4,7
    800035fa:	9f95                	subw	a5,a5,a3
    800035fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003600:	4037571b          	sraiw	a4,a4,0x3
    80003604:	00e906b3          	add	a3,s2,a4
    80003608:	0586c683          	lbu	a3,88(a3)
    8000360c:	00d7f5b3          	and	a1,a5,a3
    80003610:	d195                	beqz	a1,80003534 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003612:	2605                	addiw	a2,a2,1
    80003614:	2485                	addiw	s1,s1,1
    80003616:	fd4618e3          	bne	a2,s4,800035e6 <balloc+0xee>
    8000361a:	b759                	j	800035a0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	f5450513          	addi	a0,a0,-172 # 80008570 <syscalls+0x120>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f64080e7          	jalr	-156(ra) # 80000588 <printf>
  return 0;
    8000362c:	4481                	li	s1,0
    8000362e:	bf99                	j	80003584 <balloc+0x8c>

0000000080003630 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	e052                	sd	s4,0(sp)
    8000363e:	1800                	addi	s0,sp,48
    80003640:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003642:	47ad                	li	a5,11
    80003644:	02b7e763          	bltu	a5,a1,80003672 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003648:	02059493          	slli	s1,a1,0x20
    8000364c:	9081                	srli	s1,s1,0x20
    8000364e:	048a                	slli	s1,s1,0x2
    80003650:	94aa                	add	s1,s1,a0
    80003652:	0504a903          	lw	s2,80(s1)
    80003656:	06091e63          	bnez	s2,800036d2 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000365a:	4108                	lw	a0,0(a0)
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	e9c080e7          	jalr	-356(ra) # 800034f8 <balloc>
    80003664:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003668:	06090563          	beqz	s2,800036d2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000366c:	0524a823          	sw	s2,80(s1)
    80003670:	a08d                	j	800036d2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003672:	ff45849b          	addiw	s1,a1,-12
    80003676:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000367a:	0ff00793          	li	a5,255
    8000367e:	08e7e563          	bltu	a5,a4,80003708 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003682:	08052903          	lw	s2,128(a0)
    80003686:	00091d63          	bnez	s2,800036a0 <bmap+0x70>
      addr = balloc(ip->dev);
    8000368a:	4108                	lw	a0,0(a0)
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	e6c080e7          	jalr	-404(ra) # 800034f8 <balloc>
    80003694:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003698:	02090d63          	beqz	s2,800036d2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000369c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036a0:	85ca                	mv	a1,s2
    800036a2:	0009a503          	lw	a0,0(s3)
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	b90080e7          	jalr	-1136(ra) # 80003236 <bread>
    800036ae:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036b0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036b4:	02049593          	slli	a1,s1,0x20
    800036b8:	9181                	srli	a1,a1,0x20
    800036ba:	058a                	slli	a1,a1,0x2
    800036bc:	00b784b3          	add	s1,a5,a1
    800036c0:	0004a903          	lw	s2,0(s1)
    800036c4:	02090063          	beqz	s2,800036e4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036c8:	8552                	mv	a0,s4
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	c9c080e7          	jalr	-868(ra) # 80003366 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036d2:	854a                	mv	a0,s2
    800036d4:	70a2                	ld	ra,40(sp)
    800036d6:	7402                	ld	s0,32(sp)
    800036d8:	64e2                	ld	s1,24(sp)
    800036da:	6942                	ld	s2,16(sp)
    800036dc:	69a2                	ld	s3,8(sp)
    800036de:	6a02                	ld	s4,0(sp)
    800036e0:	6145                	addi	sp,sp,48
    800036e2:	8082                	ret
      addr = balloc(ip->dev);
    800036e4:	0009a503          	lw	a0,0(s3)
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	e10080e7          	jalr	-496(ra) # 800034f8 <balloc>
    800036f0:	0005091b          	sext.w	s2,a0
      if(addr){
    800036f4:	fc090ae3          	beqz	s2,800036c8 <bmap+0x98>
        a[bn] = addr;
    800036f8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036fc:	8552                	mv	a0,s4
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	eec080e7          	jalr	-276(ra) # 800045ea <log_write>
    80003706:	b7c9                	j	800036c8 <bmap+0x98>
  panic("bmap: out of range");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	e8050513          	addi	a0,a0,-384 # 80008588 <syscalls+0x138>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>

0000000080003718 <iget>:
{
    80003718:	7179                	addi	sp,sp,-48
    8000371a:	f406                	sd	ra,40(sp)
    8000371c:	f022                	sd	s0,32(sp)
    8000371e:	ec26                	sd	s1,24(sp)
    80003720:	e84a                	sd	s2,16(sp)
    80003722:	e44e                	sd	s3,8(sp)
    80003724:	e052                	sd	s4,0(sp)
    80003726:	1800                	addi	s0,sp,48
    80003728:	89aa                	mv	s3,a0
    8000372a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000372c:	0001c517          	auipc	a0,0x1c
    80003730:	54c50513          	addi	a0,a0,1356 # 8001fc78 <itable>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	4a2080e7          	jalr	1186(ra) # 80000bd6 <acquire>
  empty = 0;
    8000373c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000373e:	0001c497          	auipc	s1,0x1c
    80003742:	55248493          	addi	s1,s1,1362 # 8001fc90 <itable+0x18>
    80003746:	0001e697          	auipc	a3,0x1e
    8000374a:	fda68693          	addi	a3,a3,-38 # 80021720 <log>
    8000374e:	a039                	j	8000375c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003750:	02090b63          	beqz	s2,80003786 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003754:	08848493          	addi	s1,s1,136
    80003758:	02d48a63          	beq	s1,a3,8000378c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000375c:	449c                	lw	a5,8(s1)
    8000375e:	fef059e3          	blez	a5,80003750 <iget+0x38>
    80003762:	4098                	lw	a4,0(s1)
    80003764:	ff3716e3          	bne	a4,s3,80003750 <iget+0x38>
    80003768:	40d8                	lw	a4,4(s1)
    8000376a:	ff4713e3          	bne	a4,s4,80003750 <iget+0x38>
      ip->ref++;
    8000376e:	2785                	addiw	a5,a5,1
    80003770:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003772:	0001c517          	auipc	a0,0x1c
    80003776:	50650513          	addi	a0,a0,1286 # 8001fc78 <itable>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	510080e7          	jalr	1296(ra) # 80000c8a <release>
      return ip;
    80003782:	8926                	mv	s2,s1
    80003784:	a03d                	j	800037b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003786:	f7f9                	bnez	a5,80003754 <iget+0x3c>
    80003788:	8926                	mv	s2,s1
    8000378a:	b7e9                	j	80003754 <iget+0x3c>
  if(empty == 0)
    8000378c:	02090c63          	beqz	s2,800037c4 <iget+0xac>
  ip->dev = dev;
    80003790:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003794:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003798:	4785                	li	a5,1
    8000379a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000379e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037a2:	0001c517          	auipc	a0,0x1c
    800037a6:	4d650513          	addi	a0,a0,1238 # 8001fc78 <itable>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	4e0080e7          	jalr	1248(ra) # 80000c8a <release>
}
    800037b2:	854a                	mv	a0,s2
    800037b4:	70a2                	ld	ra,40(sp)
    800037b6:	7402                	ld	s0,32(sp)
    800037b8:	64e2                	ld	s1,24(sp)
    800037ba:	6942                	ld	s2,16(sp)
    800037bc:	69a2                	ld	s3,8(sp)
    800037be:	6a02                	ld	s4,0(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret
    panic("iget: no inodes");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	ddc50513          	addi	a0,a0,-548 # 800085a0 <syscalls+0x150>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>

00000000800037d4 <fsinit>:
fsinit(int dev) {
    800037d4:	7179                	addi	sp,sp,-48
    800037d6:	f406                	sd	ra,40(sp)
    800037d8:	f022                	sd	s0,32(sp)
    800037da:	ec26                	sd	s1,24(sp)
    800037dc:	e84a                	sd	s2,16(sp)
    800037de:	e44e                	sd	s3,8(sp)
    800037e0:	1800                	addi	s0,sp,48
    800037e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037e4:	4585                	li	a1,1
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	a50080e7          	jalr	-1456(ra) # 80003236 <bread>
    800037ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f0:	0001c997          	auipc	s3,0x1c
    800037f4:	46898993          	addi	s3,s3,1128 # 8001fc58 <sb>
    800037f8:	02000613          	li	a2,32
    800037fc:	05850593          	addi	a1,a0,88
    80003800:	854e                	mv	a0,s3
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	52c080e7          	jalr	1324(ra) # 80000d2e <memmove>
  brelse(bp);
    8000380a:	8526                	mv	a0,s1
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	b5a080e7          	jalr	-1190(ra) # 80003366 <brelse>
  if(sb.magic != FSMAGIC)
    80003814:	0009a703          	lw	a4,0(s3)
    80003818:	102037b7          	lui	a5,0x10203
    8000381c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003820:	02f71263          	bne	a4,a5,80003844 <fsinit+0x70>
  initlog(dev, &sb);
    80003824:	0001c597          	auipc	a1,0x1c
    80003828:	43458593          	addi	a1,a1,1076 # 8001fc58 <sb>
    8000382c:	854a                	mv	a0,s2
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	b40080e7          	jalr	-1216(ra) # 8000436e <initlog>
}
    80003836:	70a2                	ld	ra,40(sp)
    80003838:	7402                	ld	s0,32(sp)
    8000383a:	64e2                	ld	s1,24(sp)
    8000383c:	6942                	ld	s2,16(sp)
    8000383e:	69a2                	ld	s3,8(sp)
    80003840:	6145                	addi	sp,sp,48
    80003842:	8082                	ret
    panic("invalid file system");
    80003844:	00005517          	auipc	a0,0x5
    80003848:	d6c50513          	addi	a0,a0,-660 # 800085b0 <syscalls+0x160>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>

0000000080003854 <iinit>:
{
    80003854:	7179                	addi	sp,sp,-48
    80003856:	f406                	sd	ra,40(sp)
    80003858:	f022                	sd	s0,32(sp)
    8000385a:	ec26                	sd	s1,24(sp)
    8000385c:	e84a                	sd	s2,16(sp)
    8000385e:	e44e                	sd	s3,8(sp)
    80003860:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003862:	00005597          	auipc	a1,0x5
    80003866:	d6658593          	addi	a1,a1,-666 # 800085c8 <syscalls+0x178>
    8000386a:	0001c517          	auipc	a0,0x1c
    8000386e:	40e50513          	addi	a0,a0,1038 # 8001fc78 <itable>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	2d4080e7          	jalr	724(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000387a:	0001c497          	auipc	s1,0x1c
    8000387e:	42648493          	addi	s1,s1,1062 # 8001fca0 <itable+0x28>
    80003882:	0001e997          	auipc	s3,0x1e
    80003886:	eae98993          	addi	s3,s3,-338 # 80021730 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000388a:	00005917          	auipc	s2,0x5
    8000388e:	d4690913          	addi	s2,s2,-698 # 800085d0 <syscalls+0x180>
    80003892:	85ca                	mv	a1,s2
    80003894:	8526                	mv	a0,s1
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	e3a080e7          	jalr	-454(ra) # 800046d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000389e:	08848493          	addi	s1,s1,136
    800038a2:	ff3498e3          	bne	s1,s3,80003892 <iinit+0x3e>
}
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret

00000000800038b4 <ialloc>:
{
    800038b4:	715d                	addi	sp,sp,-80
    800038b6:	e486                	sd	ra,72(sp)
    800038b8:	e0a2                	sd	s0,64(sp)
    800038ba:	fc26                	sd	s1,56(sp)
    800038bc:	f84a                	sd	s2,48(sp)
    800038be:	f44e                	sd	s3,40(sp)
    800038c0:	f052                	sd	s4,32(sp)
    800038c2:	ec56                	sd	s5,24(sp)
    800038c4:	e85a                	sd	s6,16(sp)
    800038c6:	e45e                	sd	s7,8(sp)
    800038c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ca:	0001c717          	auipc	a4,0x1c
    800038ce:	39a72703          	lw	a4,922(a4) # 8001fc64 <sb+0xc>
    800038d2:	4785                	li	a5,1
    800038d4:	04e7fa63          	bgeu	a5,a4,80003928 <ialloc+0x74>
    800038d8:	8aaa                	mv	s5,a0
    800038da:	8bae                	mv	s7,a1
    800038dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038de:	0001ca17          	auipc	s4,0x1c
    800038e2:	37aa0a13          	addi	s4,s4,890 # 8001fc58 <sb>
    800038e6:	00048b1b          	sext.w	s6,s1
    800038ea:	0044d793          	srli	a5,s1,0x4
    800038ee:	018a2583          	lw	a1,24(s4)
    800038f2:	9dbd                	addw	a1,a1,a5
    800038f4:	8556                	mv	a0,s5
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	940080e7          	jalr	-1728(ra) # 80003236 <bread>
    800038fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003900:	05850993          	addi	s3,a0,88
    80003904:	00f4f793          	andi	a5,s1,15
    80003908:	079a                	slli	a5,a5,0x6
    8000390a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000390c:	00099783          	lh	a5,0(s3)
    80003910:	c3a1                	beqz	a5,80003950 <ialloc+0x9c>
    brelse(bp);
    80003912:	00000097          	auipc	ra,0x0
    80003916:	a54080e7          	jalr	-1452(ra) # 80003366 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000391a:	0485                	addi	s1,s1,1
    8000391c:	00ca2703          	lw	a4,12(s4)
    80003920:	0004879b          	sext.w	a5,s1
    80003924:	fce7e1e3          	bltu	a5,a4,800038e6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003928:	00005517          	auipc	a0,0x5
    8000392c:	cb050513          	addi	a0,a0,-848 # 800085d8 <syscalls+0x188>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	c58080e7          	jalr	-936(ra) # 80000588 <printf>
  return 0;
    80003938:	4501                	li	a0,0
}
    8000393a:	60a6                	ld	ra,72(sp)
    8000393c:	6406                	ld	s0,64(sp)
    8000393e:	74e2                	ld	s1,56(sp)
    80003940:	7942                	ld	s2,48(sp)
    80003942:	79a2                	ld	s3,40(sp)
    80003944:	7a02                	ld	s4,32(sp)
    80003946:	6ae2                	ld	s5,24(sp)
    80003948:	6b42                	ld	s6,16(sp)
    8000394a:	6ba2                	ld	s7,8(sp)
    8000394c:	6161                	addi	sp,sp,80
    8000394e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003950:	04000613          	li	a2,64
    80003954:	4581                	li	a1,0
    80003956:	854e                	mv	a0,s3
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	37a080e7          	jalr	890(ra) # 80000cd2 <memset>
      dip->type = type;
    80003960:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003964:	854a                	mv	a0,s2
    80003966:	00001097          	auipc	ra,0x1
    8000396a:	c84080e7          	jalr	-892(ra) # 800045ea <log_write>
      brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	00000097          	auipc	ra,0x0
    80003974:	9f6080e7          	jalr	-1546(ra) # 80003366 <brelse>
      return iget(dev, inum);
    80003978:	85da                	mv	a1,s6
    8000397a:	8556                	mv	a0,s5
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	d9c080e7          	jalr	-612(ra) # 80003718 <iget>
    80003984:	bf5d                	j	8000393a <ialloc+0x86>

0000000080003986 <iupdate>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	e04a                	sd	s2,0(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003994:	415c                	lw	a5,4(a0)
    80003996:	0047d79b          	srliw	a5,a5,0x4
    8000399a:	0001c597          	auipc	a1,0x1c
    8000399e:	2d65a583          	lw	a1,726(a1) # 8001fc70 <sb+0x18>
    800039a2:	9dbd                	addw	a1,a1,a5
    800039a4:	4108                	lw	a0,0(a0)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	890080e7          	jalr	-1904(ra) # 80003236 <bread>
    800039ae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b0:	05850793          	addi	a5,a0,88
    800039b4:	40c8                	lw	a0,4(s1)
    800039b6:	893d                	andi	a0,a0,15
    800039b8:	051a                	slli	a0,a0,0x6
    800039ba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039bc:	04449703          	lh	a4,68(s1)
    800039c0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039c4:	04649703          	lh	a4,70(s1)
    800039c8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039cc:	04849703          	lh	a4,72(s1)
    800039d0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039d4:	04a49703          	lh	a4,74(s1)
    800039d8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039dc:	44f8                	lw	a4,76(s1)
    800039de:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039e0:	03400613          	li	a2,52
    800039e4:	05048593          	addi	a1,s1,80
    800039e8:	0531                	addi	a0,a0,12
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	344080e7          	jalr	836(ra) # 80000d2e <memmove>
  log_write(bp);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	bf6080e7          	jalr	-1034(ra) # 800045ea <log_write>
  brelse(bp);
    800039fc:	854a                	mv	a0,s2
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	968080e7          	jalr	-1688(ra) # 80003366 <brelse>
}
    80003a06:	60e2                	ld	ra,24(sp)
    80003a08:	6442                	ld	s0,16(sp)
    80003a0a:	64a2                	ld	s1,8(sp)
    80003a0c:	6902                	ld	s2,0(sp)
    80003a0e:	6105                	addi	sp,sp,32
    80003a10:	8082                	ret

0000000080003a12 <idup>:
{
    80003a12:	1101                	addi	sp,sp,-32
    80003a14:	ec06                	sd	ra,24(sp)
    80003a16:	e822                	sd	s0,16(sp)
    80003a18:	e426                	sd	s1,8(sp)
    80003a1a:	1000                	addi	s0,sp,32
    80003a1c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	25a50513          	addi	a0,a0,602 # 8001fc78 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a2e:	449c                	lw	a5,8(s1)
    80003a30:	2785                	addiw	a5,a5,1
    80003a32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a34:	0001c517          	auipc	a0,0x1c
    80003a38:	24450513          	addi	a0,a0,580 # 8001fc78 <itable>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80003a44:	8526                	mv	a0,s1
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	64a2                	ld	s1,8(sp)
    80003a4c:	6105                	addi	sp,sp,32
    80003a4e:	8082                	ret

0000000080003a50 <ilock>:
{
    80003a50:	1101                	addi	sp,sp,-32
    80003a52:	ec06                	sd	ra,24(sp)
    80003a54:	e822                	sd	s0,16(sp)
    80003a56:	e426                	sd	s1,8(sp)
    80003a58:	e04a                	sd	s2,0(sp)
    80003a5a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a5c:	c115                	beqz	a0,80003a80 <ilock+0x30>
    80003a5e:	84aa                	mv	s1,a0
    80003a60:	451c                	lw	a5,8(a0)
    80003a62:	00f05f63          	blez	a5,80003a80 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a66:	0541                	addi	a0,a0,16
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	ca2080e7          	jalr	-862(ra) # 8000470a <acquiresleep>
  if(ip->valid == 0){
    80003a70:	40bc                	lw	a5,64(s1)
    80003a72:	cf99                	beqz	a5,80003a90 <ilock+0x40>
}
    80003a74:	60e2                	ld	ra,24(sp)
    80003a76:	6442                	ld	s0,16(sp)
    80003a78:	64a2                	ld	s1,8(sp)
    80003a7a:	6902                	ld	s2,0(sp)
    80003a7c:	6105                	addi	sp,sp,32
    80003a7e:	8082                	ret
    panic("ilock");
    80003a80:	00005517          	auipc	a0,0x5
    80003a84:	b7050513          	addi	a0,a0,-1168 # 800085f0 <syscalls+0x1a0>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a90:	40dc                	lw	a5,4(s1)
    80003a92:	0047d79b          	srliw	a5,a5,0x4
    80003a96:	0001c597          	auipc	a1,0x1c
    80003a9a:	1da5a583          	lw	a1,474(a1) # 8001fc70 <sb+0x18>
    80003a9e:	9dbd                	addw	a1,a1,a5
    80003aa0:	4088                	lw	a0,0(s1)
    80003aa2:	fffff097          	auipc	ra,0xfffff
    80003aa6:	794080e7          	jalr	1940(ra) # 80003236 <bread>
    80003aaa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aac:	05850593          	addi	a1,a0,88
    80003ab0:	40dc                	lw	a5,4(s1)
    80003ab2:	8bbd                	andi	a5,a5,15
    80003ab4:	079a                	slli	a5,a5,0x6
    80003ab6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ab8:	00059783          	lh	a5,0(a1)
    80003abc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ac0:	00259783          	lh	a5,2(a1)
    80003ac4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ac8:	00459783          	lh	a5,4(a1)
    80003acc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ad0:	00659783          	lh	a5,6(a1)
    80003ad4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ad8:	459c                	lw	a5,8(a1)
    80003ada:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003adc:	03400613          	li	a2,52
    80003ae0:	05b1                	addi	a1,a1,12
    80003ae2:	05048513          	addi	a0,s1,80
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	248080e7          	jalr	584(ra) # 80000d2e <memmove>
    brelse(bp);
    80003aee:	854a                	mv	a0,s2
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	876080e7          	jalr	-1930(ra) # 80003366 <brelse>
    ip->valid = 1;
    80003af8:	4785                	li	a5,1
    80003afa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003afc:	04449783          	lh	a5,68(s1)
    80003b00:	fbb5                	bnez	a5,80003a74 <ilock+0x24>
      panic("ilock: no type");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	af650513          	addi	a0,a0,-1290 # 800085f8 <syscalls+0x1a8>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a34080e7          	jalr	-1484(ra) # 8000053e <panic>

0000000080003b12 <iunlock>:
{
    80003b12:	1101                	addi	sp,sp,-32
    80003b14:	ec06                	sd	ra,24(sp)
    80003b16:	e822                	sd	s0,16(sp)
    80003b18:	e426                	sd	s1,8(sp)
    80003b1a:	e04a                	sd	s2,0(sp)
    80003b1c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b1e:	c905                	beqz	a0,80003b4e <iunlock+0x3c>
    80003b20:	84aa                	mv	s1,a0
    80003b22:	01050913          	addi	s2,a0,16
    80003b26:	854a                	mv	a0,s2
    80003b28:	00001097          	auipc	ra,0x1
    80003b2c:	c7c080e7          	jalr	-900(ra) # 800047a4 <holdingsleep>
    80003b30:	cd19                	beqz	a0,80003b4e <iunlock+0x3c>
    80003b32:	449c                	lw	a5,8(s1)
    80003b34:	00f05d63          	blez	a5,80003b4e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00001097          	auipc	ra,0x1
    80003b3e:	c26080e7          	jalr	-986(ra) # 80004760 <releasesleep>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6902                	ld	s2,0(sp)
    80003b4a:	6105                	addi	sp,sp,32
    80003b4c:	8082                	ret
    panic("iunlock");
    80003b4e:	00005517          	auipc	a0,0x5
    80003b52:	aba50513          	addi	a0,a0,-1350 # 80008608 <syscalls+0x1b8>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	9e8080e7          	jalr	-1560(ra) # 8000053e <panic>

0000000080003b5e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b5e:	7179                	addi	sp,sp,-48
    80003b60:	f406                	sd	ra,40(sp)
    80003b62:	f022                	sd	s0,32(sp)
    80003b64:	ec26                	sd	s1,24(sp)
    80003b66:	e84a                	sd	s2,16(sp)
    80003b68:	e44e                	sd	s3,8(sp)
    80003b6a:	e052                	sd	s4,0(sp)
    80003b6c:	1800                	addi	s0,sp,48
    80003b6e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b70:	05050493          	addi	s1,a0,80
    80003b74:	08050913          	addi	s2,a0,128
    80003b78:	a021                	j	80003b80 <itrunc+0x22>
    80003b7a:	0491                	addi	s1,s1,4
    80003b7c:	01248d63          	beq	s1,s2,80003b96 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b80:	408c                	lw	a1,0(s1)
    80003b82:	dde5                	beqz	a1,80003b7a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b84:	0009a503          	lw	a0,0(s3)
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	8f4080e7          	jalr	-1804(ra) # 8000347c <bfree>
      ip->addrs[i] = 0;
    80003b90:	0004a023          	sw	zero,0(s1)
    80003b94:	b7dd                	j	80003b7a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b96:	0809a583          	lw	a1,128(s3)
    80003b9a:	e185                	bnez	a1,80003bba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b9c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ba0:	854e                	mv	a0,s3
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	de4080e7          	jalr	-540(ra) # 80003986 <iupdate>
}
    80003baa:	70a2                	ld	ra,40(sp)
    80003bac:	7402                	ld	s0,32(sp)
    80003bae:	64e2                	ld	s1,24(sp)
    80003bb0:	6942                	ld	s2,16(sp)
    80003bb2:	69a2                	ld	s3,8(sp)
    80003bb4:	6a02                	ld	s4,0(sp)
    80003bb6:	6145                	addi	sp,sp,48
    80003bb8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bba:	0009a503          	lw	a0,0(s3)
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	678080e7          	jalr	1656(ra) # 80003236 <bread>
    80003bc6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bc8:	05850493          	addi	s1,a0,88
    80003bcc:	45850913          	addi	s2,a0,1112
    80003bd0:	a021                	j	80003bd8 <itrunc+0x7a>
    80003bd2:	0491                	addi	s1,s1,4
    80003bd4:	01248b63          	beq	s1,s2,80003bea <itrunc+0x8c>
      if(a[j])
    80003bd8:	408c                	lw	a1,0(s1)
    80003bda:	dde5                	beqz	a1,80003bd2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bdc:	0009a503          	lw	a0,0(s3)
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	89c080e7          	jalr	-1892(ra) # 8000347c <bfree>
    80003be8:	b7ed                	j	80003bd2 <itrunc+0x74>
    brelse(bp);
    80003bea:	8552                	mv	a0,s4
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	77a080e7          	jalr	1914(ra) # 80003366 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf4:	0809a583          	lw	a1,128(s3)
    80003bf8:	0009a503          	lw	a0,0(s3)
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	880080e7          	jalr	-1920(ra) # 8000347c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c04:	0809a023          	sw	zero,128(s3)
    80003c08:	bf51                	j	80003b9c <itrunc+0x3e>

0000000080003c0a <iput>:
{
    80003c0a:	1101                	addi	sp,sp,-32
    80003c0c:	ec06                	sd	ra,24(sp)
    80003c0e:	e822                	sd	s0,16(sp)
    80003c10:	e426                	sd	s1,8(sp)
    80003c12:	e04a                	sd	s2,0(sp)
    80003c14:	1000                	addi	s0,sp,32
    80003c16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c18:	0001c517          	auipc	a0,0x1c
    80003c1c:	06050513          	addi	a0,a0,96 # 8001fc78 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	fb6080e7          	jalr	-74(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c28:	4498                	lw	a4,8(s1)
    80003c2a:	4785                	li	a5,1
    80003c2c:	02f70363          	beq	a4,a5,80003c52 <iput+0x48>
  ip->ref--;
    80003c30:	449c                	lw	a5,8(s1)
    80003c32:	37fd                	addiw	a5,a5,-1
    80003c34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c36:	0001c517          	auipc	a0,0x1c
    80003c3a:	04250513          	addi	a0,a0,66 # 8001fc78 <itable>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	04c080e7          	jalr	76(ra) # 80000c8a <release>
}
    80003c46:	60e2                	ld	ra,24(sp)
    80003c48:	6442                	ld	s0,16(sp)
    80003c4a:	64a2                	ld	s1,8(sp)
    80003c4c:	6902                	ld	s2,0(sp)
    80003c4e:	6105                	addi	sp,sp,32
    80003c50:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c52:	40bc                	lw	a5,64(s1)
    80003c54:	dff1                	beqz	a5,80003c30 <iput+0x26>
    80003c56:	04a49783          	lh	a5,74(s1)
    80003c5a:	fbf9                	bnez	a5,80003c30 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c5c:	01048913          	addi	s2,s1,16
    80003c60:	854a                	mv	a0,s2
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	aa8080e7          	jalr	-1368(ra) # 8000470a <acquiresleep>
    release(&itable.lock);
    80003c6a:	0001c517          	auipc	a0,0x1c
    80003c6e:	00e50513          	addi	a0,a0,14 # 8001fc78 <itable>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	018080e7          	jalr	24(ra) # 80000c8a <release>
    itrunc(ip);
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	ee2080e7          	jalr	-286(ra) # 80003b5e <itrunc>
    ip->type = 0;
    80003c84:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c88:	8526                	mv	a0,s1
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	cfc080e7          	jalr	-772(ra) # 80003986 <iupdate>
    ip->valid = 0;
    80003c92:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c96:	854a                	mv	a0,s2
    80003c98:	00001097          	auipc	ra,0x1
    80003c9c:	ac8080e7          	jalr	-1336(ra) # 80004760 <releasesleep>
    acquire(&itable.lock);
    80003ca0:	0001c517          	auipc	a0,0x1c
    80003ca4:	fd850513          	addi	a0,a0,-40 # 8001fc78 <itable>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	f2e080e7          	jalr	-210(ra) # 80000bd6 <acquire>
    80003cb0:	b741                	j	80003c30 <iput+0x26>

0000000080003cb2 <iunlockput>:
{
    80003cb2:	1101                	addi	sp,sp,-32
    80003cb4:	ec06                	sd	ra,24(sp)
    80003cb6:	e822                	sd	s0,16(sp)
    80003cb8:	e426                	sd	s1,8(sp)
    80003cba:	1000                	addi	s0,sp,32
    80003cbc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	e54080e7          	jalr	-428(ra) # 80003b12 <iunlock>
  iput(ip);
    80003cc6:	8526                	mv	a0,s1
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	f42080e7          	jalr	-190(ra) # 80003c0a <iput>
}
    80003cd0:	60e2                	ld	ra,24(sp)
    80003cd2:	6442                	ld	s0,16(sp)
    80003cd4:	64a2                	ld	s1,8(sp)
    80003cd6:	6105                	addi	sp,sp,32
    80003cd8:	8082                	ret

0000000080003cda <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cda:	1141                	addi	sp,sp,-16
    80003cdc:	e422                	sd	s0,8(sp)
    80003cde:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ce0:	411c                	lw	a5,0(a0)
    80003ce2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce4:	415c                	lw	a5,4(a0)
    80003ce6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ce8:	04451783          	lh	a5,68(a0)
    80003cec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cf0:	04a51783          	lh	a5,74(a0)
    80003cf4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cf8:	04c56783          	lwu	a5,76(a0)
    80003cfc:	e99c                	sd	a5,16(a1)
}
    80003cfe:	6422                	ld	s0,8(sp)
    80003d00:	0141                	addi	sp,sp,16
    80003d02:	8082                	ret

0000000080003d04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d04:	457c                	lw	a5,76(a0)
    80003d06:	0ed7e963          	bltu	a5,a3,80003df8 <readi+0xf4>
{
    80003d0a:	7159                	addi	sp,sp,-112
    80003d0c:	f486                	sd	ra,104(sp)
    80003d0e:	f0a2                	sd	s0,96(sp)
    80003d10:	eca6                	sd	s1,88(sp)
    80003d12:	e8ca                	sd	s2,80(sp)
    80003d14:	e4ce                	sd	s3,72(sp)
    80003d16:	e0d2                	sd	s4,64(sp)
    80003d18:	fc56                	sd	s5,56(sp)
    80003d1a:	f85a                	sd	s6,48(sp)
    80003d1c:	f45e                	sd	s7,40(sp)
    80003d1e:	f062                	sd	s8,32(sp)
    80003d20:	ec66                	sd	s9,24(sp)
    80003d22:	e86a                	sd	s10,16(sp)
    80003d24:	e46e                	sd	s11,8(sp)
    80003d26:	1880                	addi	s0,sp,112
    80003d28:	8b2a                	mv	s6,a0
    80003d2a:	8bae                	mv	s7,a1
    80003d2c:	8a32                	mv	s4,a2
    80003d2e:	84b6                	mv	s1,a3
    80003d30:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d32:	9f35                	addw	a4,a4,a3
    return 0;
    80003d34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d36:	0ad76063          	bltu	a4,a3,80003dd6 <readi+0xd2>
  if(off + n > ip->size)
    80003d3a:	00e7f463          	bgeu	a5,a4,80003d42 <readi+0x3e>
    n = ip->size - off;
    80003d3e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d42:	0a0a8963          	beqz	s5,80003df4 <readi+0xf0>
    80003d46:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d48:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d4c:	5c7d                	li	s8,-1
    80003d4e:	a82d                	j	80003d88 <readi+0x84>
    80003d50:	020d1d93          	slli	s11,s10,0x20
    80003d54:	020ddd93          	srli	s11,s11,0x20
    80003d58:	05890793          	addi	a5,s2,88
    80003d5c:	86ee                	mv	a3,s11
    80003d5e:	963e                	add	a2,a2,a5
    80003d60:	85d2                	mv	a1,s4
    80003d62:	855e                	mv	a0,s7
    80003d64:	ffffe097          	auipc	ra,0xffffe
    80003d68:	794080e7          	jalr	1940(ra) # 800024f8 <either_copyout>
    80003d6c:	05850d63          	beq	a0,s8,80003dc6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d70:	854a                	mv	a0,s2
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	5f4080e7          	jalr	1524(ra) # 80003366 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7a:	013d09bb          	addw	s3,s10,s3
    80003d7e:	009d04bb          	addw	s1,s10,s1
    80003d82:	9a6e                	add	s4,s4,s11
    80003d84:	0559f763          	bgeu	s3,s5,80003dd2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d88:	00a4d59b          	srliw	a1,s1,0xa
    80003d8c:	855a                	mv	a0,s6
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	8a2080e7          	jalr	-1886(ra) # 80003630 <bmap>
    80003d96:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d9a:	cd85                	beqz	a1,80003dd2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d9c:	000b2503          	lw	a0,0(s6)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	496080e7          	jalr	1174(ra) # 80003236 <bread>
    80003da8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003daa:	3ff4f613          	andi	a2,s1,1023
    80003dae:	40cc87bb          	subw	a5,s9,a2
    80003db2:	413a873b          	subw	a4,s5,s3
    80003db6:	8d3e                	mv	s10,a5
    80003db8:	2781                	sext.w	a5,a5
    80003dba:	0007069b          	sext.w	a3,a4
    80003dbe:	f8f6f9e3          	bgeu	a3,a5,80003d50 <readi+0x4c>
    80003dc2:	8d3a                	mv	s10,a4
    80003dc4:	b771                	j	80003d50 <readi+0x4c>
      brelse(bp);
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	59e080e7          	jalr	1438(ra) # 80003366 <brelse>
      tot = -1;
    80003dd0:	59fd                	li	s3,-1
  }
  return tot;
    80003dd2:	0009851b          	sext.w	a0,s3
}
    80003dd6:	70a6                	ld	ra,104(sp)
    80003dd8:	7406                	ld	s0,96(sp)
    80003dda:	64e6                	ld	s1,88(sp)
    80003ddc:	6946                	ld	s2,80(sp)
    80003dde:	69a6                	ld	s3,72(sp)
    80003de0:	6a06                	ld	s4,64(sp)
    80003de2:	7ae2                	ld	s5,56(sp)
    80003de4:	7b42                	ld	s6,48(sp)
    80003de6:	7ba2                	ld	s7,40(sp)
    80003de8:	7c02                	ld	s8,32(sp)
    80003dea:	6ce2                	ld	s9,24(sp)
    80003dec:	6d42                	ld	s10,16(sp)
    80003dee:	6da2                	ld	s11,8(sp)
    80003df0:	6165                	addi	sp,sp,112
    80003df2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df4:	89d6                	mv	s3,s5
    80003df6:	bff1                	j	80003dd2 <readi+0xce>
    return 0;
    80003df8:	4501                	li	a0,0
}
    80003dfa:	8082                	ret

0000000080003dfc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dfc:	457c                	lw	a5,76(a0)
    80003dfe:	10d7e863          	bltu	a5,a3,80003f0e <writei+0x112>
{
    80003e02:	7159                	addi	sp,sp,-112
    80003e04:	f486                	sd	ra,104(sp)
    80003e06:	f0a2                	sd	s0,96(sp)
    80003e08:	eca6                	sd	s1,88(sp)
    80003e0a:	e8ca                	sd	s2,80(sp)
    80003e0c:	e4ce                	sd	s3,72(sp)
    80003e0e:	e0d2                	sd	s4,64(sp)
    80003e10:	fc56                	sd	s5,56(sp)
    80003e12:	f85a                	sd	s6,48(sp)
    80003e14:	f45e                	sd	s7,40(sp)
    80003e16:	f062                	sd	s8,32(sp)
    80003e18:	ec66                	sd	s9,24(sp)
    80003e1a:	e86a                	sd	s10,16(sp)
    80003e1c:	e46e                	sd	s11,8(sp)
    80003e1e:	1880                	addi	s0,sp,112
    80003e20:	8aaa                	mv	s5,a0
    80003e22:	8bae                	mv	s7,a1
    80003e24:	8a32                	mv	s4,a2
    80003e26:	8936                	mv	s2,a3
    80003e28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e2a:	00e687bb          	addw	a5,a3,a4
    80003e2e:	0ed7e263          	bltu	a5,a3,80003f12 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e32:	00043737          	lui	a4,0x43
    80003e36:	0ef76063          	bltu	a4,a5,80003f16 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3a:	0c0b0863          	beqz	s6,80003f0a <writei+0x10e>
    80003e3e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e40:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e44:	5c7d                	li	s8,-1
    80003e46:	a091                	j	80003e8a <writei+0x8e>
    80003e48:	020d1d93          	slli	s11,s10,0x20
    80003e4c:	020ddd93          	srli	s11,s11,0x20
    80003e50:	05848793          	addi	a5,s1,88
    80003e54:	86ee                	mv	a3,s11
    80003e56:	8652                	mv	a2,s4
    80003e58:	85de                	mv	a1,s7
    80003e5a:	953e                	add	a0,a0,a5
    80003e5c:	ffffe097          	auipc	ra,0xffffe
    80003e60:	6f2080e7          	jalr	1778(ra) # 8000254e <either_copyin>
    80003e64:	07850263          	beq	a0,s8,80003ec8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	780080e7          	jalr	1920(ra) # 800045ea <log_write>
    brelse(bp);
    80003e72:	8526                	mv	a0,s1
    80003e74:	fffff097          	auipc	ra,0xfffff
    80003e78:	4f2080e7          	jalr	1266(ra) # 80003366 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e7c:	013d09bb          	addw	s3,s10,s3
    80003e80:	012d093b          	addw	s2,s10,s2
    80003e84:	9a6e                	add	s4,s4,s11
    80003e86:	0569f663          	bgeu	s3,s6,80003ed2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e8a:	00a9559b          	srliw	a1,s2,0xa
    80003e8e:	8556                	mv	a0,s5
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	7a0080e7          	jalr	1952(ra) # 80003630 <bmap>
    80003e98:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e9c:	c99d                	beqz	a1,80003ed2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e9e:	000aa503          	lw	a0,0(s5)
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	394080e7          	jalr	916(ra) # 80003236 <bread>
    80003eaa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eac:	3ff97513          	andi	a0,s2,1023
    80003eb0:	40ac87bb          	subw	a5,s9,a0
    80003eb4:	413b073b          	subw	a4,s6,s3
    80003eb8:	8d3e                	mv	s10,a5
    80003eba:	2781                	sext.w	a5,a5
    80003ebc:	0007069b          	sext.w	a3,a4
    80003ec0:	f8f6f4e3          	bgeu	a3,a5,80003e48 <writei+0x4c>
    80003ec4:	8d3a                	mv	s10,a4
    80003ec6:	b749                	j	80003e48 <writei+0x4c>
      brelse(bp);
    80003ec8:	8526                	mv	a0,s1
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	49c080e7          	jalr	1180(ra) # 80003366 <brelse>
  }

  if(off > ip->size)
    80003ed2:	04caa783          	lw	a5,76(s5)
    80003ed6:	0127f463          	bgeu	a5,s2,80003ede <writei+0xe2>
    ip->size = off;
    80003eda:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ede:	8556                	mv	a0,s5
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	aa6080e7          	jalr	-1370(ra) # 80003986 <iupdate>

  return tot;
    80003ee8:	0009851b          	sext.w	a0,s3
}
    80003eec:	70a6                	ld	ra,104(sp)
    80003eee:	7406                	ld	s0,96(sp)
    80003ef0:	64e6                	ld	s1,88(sp)
    80003ef2:	6946                	ld	s2,80(sp)
    80003ef4:	69a6                	ld	s3,72(sp)
    80003ef6:	6a06                	ld	s4,64(sp)
    80003ef8:	7ae2                	ld	s5,56(sp)
    80003efa:	7b42                	ld	s6,48(sp)
    80003efc:	7ba2                	ld	s7,40(sp)
    80003efe:	7c02                	ld	s8,32(sp)
    80003f00:	6ce2                	ld	s9,24(sp)
    80003f02:	6d42                	ld	s10,16(sp)
    80003f04:	6da2                	ld	s11,8(sp)
    80003f06:	6165                	addi	sp,sp,112
    80003f08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f0a:	89da                	mv	s3,s6
    80003f0c:	bfc9                	j	80003ede <writei+0xe2>
    return -1;
    80003f0e:	557d                	li	a0,-1
}
    80003f10:	8082                	ret
    return -1;
    80003f12:	557d                	li	a0,-1
    80003f14:	bfe1                	j	80003eec <writei+0xf0>
    return -1;
    80003f16:	557d                	li	a0,-1
    80003f18:	bfd1                	j	80003eec <writei+0xf0>

0000000080003f1a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f1a:	1141                	addi	sp,sp,-16
    80003f1c:	e406                	sd	ra,8(sp)
    80003f1e:	e022                	sd	s0,0(sp)
    80003f20:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f22:	4639                	li	a2,14
    80003f24:	ffffd097          	auipc	ra,0xffffd
    80003f28:	e7e080e7          	jalr	-386(ra) # 80000da2 <strncmp>
}
    80003f2c:	60a2                	ld	ra,8(sp)
    80003f2e:	6402                	ld	s0,0(sp)
    80003f30:	0141                	addi	sp,sp,16
    80003f32:	8082                	ret

0000000080003f34 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f34:	7139                	addi	sp,sp,-64
    80003f36:	fc06                	sd	ra,56(sp)
    80003f38:	f822                	sd	s0,48(sp)
    80003f3a:	f426                	sd	s1,40(sp)
    80003f3c:	f04a                	sd	s2,32(sp)
    80003f3e:	ec4e                	sd	s3,24(sp)
    80003f40:	e852                	sd	s4,16(sp)
    80003f42:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f44:	04451703          	lh	a4,68(a0)
    80003f48:	4785                	li	a5,1
    80003f4a:	00f71a63          	bne	a4,a5,80003f5e <dirlookup+0x2a>
    80003f4e:	892a                	mv	s2,a0
    80003f50:	89ae                	mv	s3,a1
    80003f52:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f54:	457c                	lw	a5,76(a0)
    80003f56:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f58:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5a:	e79d                	bnez	a5,80003f88 <dirlookup+0x54>
    80003f5c:	a8a5                	j	80003fd4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f5e:	00004517          	auipc	a0,0x4
    80003f62:	6b250513          	addi	a0,a0,1714 # 80008610 <syscalls+0x1c0>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f6e:	00004517          	auipc	a0,0x4
    80003f72:	6ba50513          	addi	a0,a0,1722 # 80008628 <syscalls+0x1d8>
    80003f76:	ffffc097          	auipc	ra,0xffffc
    80003f7a:	5c8080e7          	jalr	1480(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7e:	24c1                	addiw	s1,s1,16
    80003f80:	04c92783          	lw	a5,76(s2)
    80003f84:	04f4f763          	bgeu	s1,a5,80003fd2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f88:	4741                	li	a4,16
    80003f8a:	86a6                	mv	a3,s1
    80003f8c:	fc040613          	addi	a2,s0,-64
    80003f90:	4581                	li	a1,0
    80003f92:	854a                	mv	a0,s2
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	d70080e7          	jalr	-656(ra) # 80003d04 <readi>
    80003f9c:	47c1                	li	a5,16
    80003f9e:	fcf518e3          	bne	a0,a5,80003f6e <dirlookup+0x3a>
    if(de.inum == 0)
    80003fa2:	fc045783          	lhu	a5,-64(s0)
    80003fa6:	dfe1                	beqz	a5,80003f7e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fa8:	fc240593          	addi	a1,s0,-62
    80003fac:	854e                	mv	a0,s3
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	f6c080e7          	jalr	-148(ra) # 80003f1a <namecmp>
    80003fb6:	f561                	bnez	a0,80003f7e <dirlookup+0x4a>
      if(poff)
    80003fb8:	000a0463          	beqz	s4,80003fc0 <dirlookup+0x8c>
        *poff = off;
    80003fbc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fc0:	fc045583          	lhu	a1,-64(s0)
    80003fc4:	00092503          	lw	a0,0(s2)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	750080e7          	jalr	1872(ra) # 80003718 <iget>
    80003fd0:	a011                	j	80003fd4 <dirlookup+0xa0>
  return 0;
    80003fd2:	4501                	li	a0,0
}
    80003fd4:	70e2                	ld	ra,56(sp)
    80003fd6:	7442                	ld	s0,48(sp)
    80003fd8:	74a2                	ld	s1,40(sp)
    80003fda:	7902                	ld	s2,32(sp)
    80003fdc:	69e2                	ld	s3,24(sp)
    80003fde:	6a42                	ld	s4,16(sp)
    80003fe0:	6121                	addi	sp,sp,64
    80003fe2:	8082                	ret

0000000080003fe4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fe4:	711d                	addi	sp,sp,-96
    80003fe6:	ec86                	sd	ra,88(sp)
    80003fe8:	e8a2                	sd	s0,80(sp)
    80003fea:	e4a6                	sd	s1,72(sp)
    80003fec:	e0ca                	sd	s2,64(sp)
    80003fee:	fc4e                	sd	s3,56(sp)
    80003ff0:	f852                	sd	s4,48(sp)
    80003ff2:	f456                	sd	s5,40(sp)
    80003ff4:	f05a                	sd	s6,32(sp)
    80003ff6:	ec5e                	sd	s7,24(sp)
    80003ff8:	e862                	sd	s8,16(sp)
    80003ffa:	e466                	sd	s9,8(sp)
    80003ffc:	1080                	addi	s0,sp,96
    80003ffe:	84aa                	mv	s1,a0
    80004000:	8aae                	mv	s5,a1
    80004002:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004004:	00054703          	lbu	a4,0(a0)
    80004008:	02f00793          	li	a5,47
    8000400c:	02f70363          	beq	a4,a5,80004032 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004010:	ffffe097          	auipc	ra,0xffffe
    80004014:	99c080e7          	jalr	-1636(ra) # 800019ac <myproc>
    80004018:	17053503          	ld	a0,368(a0)
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	9f6080e7          	jalr	-1546(ra) # 80003a12 <idup>
    80004024:	89aa                	mv	s3,a0
  while(*path == '/')
    80004026:	02f00913          	li	s2,47
  len = path - s;
    8000402a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000402c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000402e:	4b85                	li	s7,1
    80004030:	a865                	j	800040e8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004032:	4585                	li	a1,1
    80004034:	4505                	li	a0,1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	6e2080e7          	jalr	1762(ra) # 80003718 <iget>
    8000403e:	89aa                	mv	s3,a0
    80004040:	b7dd                	j	80004026 <namex+0x42>
      iunlockput(ip);
    80004042:	854e                	mv	a0,s3
    80004044:	00000097          	auipc	ra,0x0
    80004048:	c6e080e7          	jalr	-914(ra) # 80003cb2 <iunlockput>
      return 0;
    8000404c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000404e:	854e                	mv	a0,s3
    80004050:	60e6                	ld	ra,88(sp)
    80004052:	6446                	ld	s0,80(sp)
    80004054:	64a6                	ld	s1,72(sp)
    80004056:	6906                	ld	s2,64(sp)
    80004058:	79e2                	ld	s3,56(sp)
    8000405a:	7a42                	ld	s4,48(sp)
    8000405c:	7aa2                	ld	s5,40(sp)
    8000405e:	7b02                	ld	s6,32(sp)
    80004060:	6be2                	ld	s7,24(sp)
    80004062:	6c42                	ld	s8,16(sp)
    80004064:	6ca2                	ld	s9,8(sp)
    80004066:	6125                	addi	sp,sp,96
    80004068:	8082                	ret
      iunlock(ip);
    8000406a:	854e                	mv	a0,s3
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	aa6080e7          	jalr	-1370(ra) # 80003b12 <iunlock>
      return ip;
    80004074:	bfe9                	j	8000404e <namex+0x6a>
      iunlockput(ip);
    80004076:	854e                	mv	a0,s3
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	c3a080e7          	jalr	-966(ra) # 80003cb2 <iunlockput>
      return 0;
    80004080:	89e6                	mv	s3,s9
    80004082:	b7f1                	j	8000404e <namex+0x6a>
  len = path - s;
    80004084:	40b48633          	sub	a2,s1,a1
    80004088:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000408c:	099c5463          	bge	s8,s9,80004114 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004090:	4639                	li	a2,14
    80004092:	8552                	mv	a0,s4
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	c9a080e7          	jalr	-870(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000409c:	0004c783          	lbu	a5,0(s1)
    800040a0:	01279763          	bne	a5,s2,800040ae <namex+0xca>
    path++;
    800040a4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040a6:	0004c783          	lbu	a5,0(s1)
    800040aa:	ff278de3          	beq	a5,s2,800040a4 <namex+0xc0>
    ilock(ip);
    800040ae:	854e                	mv	a0,s3
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	9a0080e7          	jalr	-1632(ra) # 80003a50 <ilock>
    if(ip->type != T_DIR){
    800040b8:	04499783          	lh	a5,68(s3)
    800040bc:	f97793e3          	bne	a5,s7,80004042 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040c0:	000a8563          	beqz	s5,800040ca <namex+0xe6>
    800040c4:	0004c783          	lbu	a5,0(s1)
    800040c8:	d3cd                	beqz	a5,8000406a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040ca:	865a                	mv	a2,s6
    800040cc:	85d2                	mv	a1,s4
    800040ce:	854e                	mv	a0,s3
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	e64080e7          	jalr	-412(ra) # 80003f34 <dirlookup>
    800040d8:	8caa                	mv	s9,a0
    800040da:	dd51                	beqz	a0,80004076 <namex+0x92>
    iunlockput(ip);
    800040dc:	854e                	mv	a0,s3
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	bd4080e7          	jalr	-1068(ra) # 80003cb2 <iunlockput>
    ip = next;
    800040e6:	89e6                	mv	s3,s9
  while(*path == '/')
    800040e8:	0004c783          	lbu	a5,0(s1)
    800040ec:	05279763          	bne	a5,s2,8000413a <namex+0x156>
    path++;
    800040f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040f2:	0004c783          	lbu	a5,0(s1)
    800040f6:	ff278de3          	beq	a5,s2,800040f0 <namex+0x10c>
  if(*path == 0)
    800040fa:	c79d                	beqz	a5,80004128 <namex+0x144>
    path++;
    800040fc:	85a6                	mv	a1,s1
  len = path - s;
    800040fe:	8cda                	mv	s9,s6
    80004100:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004102:	01278963          	beq	a5,s2,80004114 <namex+0x130>
    80004106:	dfbd                	beqz	a5,80004084 <namex+0xa0>
    path++;
    80004108:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000410a:	0004c783          	lbu	a5,0(s1)
    8000410e:	ff279ce3          	bne	a5,s2,80004106 <namex+0x122>
    80004112:	bf8d                	j	80004084 <namex+0xa0>
    memmove(name, s, len);
    80004114:	2601                	sext.w	a2,a2
    80004116:	8552                	mv	a0,s4
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	c16080e7          	jalr	-1002(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004120:	9cd2                	add	s9,s9,s4
    80004122:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004126:	bf9d                	j	8000409c <namex+0xb8>
  if(nameiparent){
    80004128:	f20a83e3          	beqz	s5,8000404e <namex+0x6a>
    iput(ip);
    8000412c:	854e                	mv	a0,s3
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	adc080e7          	jalr	-1316(ra) # 80003c0a <iput>
    return 0;
    80004136:	4981                	li	s3,0
    80004138:	bf19                	j	8000404e <namex+0x6a>
  if(*path == 0)
    8000413a:	d7fd                	beqz	a5,80004128 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000413c:	0004c783          	lbu	a5,0(s1)
    80004140:	85a6                	mv	a1,s1
    80004142:	b7d1                	j	80004106 <namex+0x122>

0000000080004144 <dirlink>:
{
    80004144:	7139                	addi	sp,sp,-64
    80004146:	fc06                	sd	ra,56(sp)
    80004148:	f822                	sd	s0,48(sp)
    8000414a:	f426                	sd	s1,40(sp)
    8000414c:	f04a                	sd	s2,32(sp)
    8000414e:	ec4e                	sd	s3,24(sp)
    80004150:	e852                	sd	s4,16(sp)
    80004152:	0080                	addi	s0,sp,64
    80004154:	892a                	mv	s2,a0
    80004156:	8a2e                	mv	s4,a1
    80004158:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000415a:	4601                	li	a2,0
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	dd8080e7          	jalr	-552(ra) # 80003f34 <dirlookup>
    80004164:	e93d                	bnez	a0,800041da <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004166:	04c92483          	lw	s1,76(s2)
    8000416a:	c49d                	beqz	s1,80004198 <dirlink+0x54>
    8000416c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000416e:	4741                	li	a4,16
    80004170:	86a6                	mv	a3,s1
    80004172:	fc040613          	addi	a2,s0,-64
    80004176:	4581                	li	a1,0
    80004178:	854a                	mv	a0,s2
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	b8a080e7          	jalr	-1142(ra) # 80003d04 <readi>
    80004182:	47c1                	li	a5,16
    80004184:	06f51163          	bne	a0,a5,800041e6 <dirlink+0xa2>
    if(de.inum == 0)
    80004188:	fc045783          	lhu	a5,-64(s0)
    8000418c:	c791                	beqz	a5,80004198 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418e:	24c1                	addiw	s1,s1,16
    80004190:	04c92783          	lw	a5,76(s2)
    80004194:	fcf4ede3          	bltu	s1,a5,8000416e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004198:	4639                	li	a2,14
    8000419a:	85d2                	mv	a1,s4
    8000419c:	fc240513          	addi	a0,s0,-62
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	c3e080e7          	jalr	-962(ra) # 80000dde <strncpy>
  de.inum = inum;
    800041a8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ac:	4741                	li	a4,16
    800041ae:	86a6                	mv	a3,s1
    800041b0:	fc040613          	addi	a2,s0,-64
    800041b4:	4581                	li	a1,0
    800041b6:	854a                	mv	a0,s2
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	c44080e7          	jalr	-956(ra) # 80003dfc <writei>
    800041c0:	1541                	addi	a0,a0,-16
    800041c2:	00a03533          	snez	a0,a0
    800041c6:	40a00533          	neg	a0,a0
}
    800041ca:	70e2                	ld	ra,56(sp)
    800041cc:	7442                	ld	s0,48(sp)
    800041ce:	74a2                	ld	s1,40(sp)
    800041d0:	7902                	ld	s2,32(sp)
    800041d2:	69e2                	ld	s3,24(sp)
    800041d4:	6a42                	ld	s4,16(sp)
    800041d6:	6121                	addi	sp,sp,64
    800041d8:	8082                	ret
    iput(ip);
    800041da:	00000097          	auipc	ra,0x0
    800041de:	a30080e7          	jalr	-1488(ra) # 80003c0a <iput>
    return -1;
    800041e2:	557d                	li	a0,-1
    800041e4:	b7dd                	j	800041ca <dirlink+0x86>
      panic("dirlink read");
    800041e6:	00004517          	auipc	a0,0x4
    800041ea:	45250513          	addi	a0,a0,1106 # 80008638 <syscalls+0x1e8>
    800041ee:	ffffc097          	auipc	ra,0xffffc
    800041f2:	350080e7          	jalr	848(ra) # 8000053e <panic>

00000000800041f6 <namei>:

struct inode*
namei(char *path)
{
    800041f6:	1101                	addi	sp,sp,-32
    800041f8:	ec06                	sd	ra,24(sp)
    800041fa:	e822                	sd	s0,16(sp)
    800041fc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041fe:	fe040613          	addi	a2,s0,-32
    80004202:	4581                	li	a1,0
    80004204:	00000097          	auipc	ra,0x0
    80004208:	de0080e7          	jalr	-544(ra) # 80003fe4 <namex>
}
    8000420c:	60e2                	ld	ra,24(sp)
    8000420e:	6442                	ld	s0,16(sp)
    80004210:	6105                	addi	sp,sp,32
    80004212:	8082                	ret

0000000080004214 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004214:	1141                	addi	sp,sp,-16
    80004216:	e406                	sd	ra,8(sp)
    80004218:	e022                	sd	s0,0(sp)
    8000421a:	0800                	addi	s0,sp,16
    8000421c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000421e:	4585                	li	a1,1
    80004220:	00000097          	auipc	ra,0x0
    80004224:	dc4080e7          	jalr	-572(ra) # 80003fe4 <namex>
}
    80004228:	60a2                	ld	ra,8(sp)
    8000422a:	6402                	ld	s0,0(sp)
    8000422c:	0141                	addi	sp,sp,16
    8000422e:	8082                	ret

0000000080004230 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004230:	1101                	addi	sp,sp,-32
    80004232:	ec06                	sd	ra,24(sp)
    80004234:	e822                	sd	s0,16(sp)
    80004236:	e426                	sd	s1,8(sp)
    80004238:	e04a                	sd	s2,0(sp)
    8000423a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000423c:	0001d917          	auipc	s2,0x1d
    80004240:	4e490913          	addi	s2,s2,1252 # 80021720 <log>
    80004244:	01892583          	lw	a1,24(s2)
    80004248:	02892503          	lw	a0,40(s2)
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	fea080e7          	jalr	-22(ra) # 80003236 <bread>
    80004254:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004256:	02c92683          	lw	a3,44(s2)
    8000425a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000425c:	02d05763          	blez	a3,8000428a <write_head+0x5a>
    80004260:	0001d797          	auipc	a5,0x1d
    80004264:	4f078793          	addi	a5,a5,1264 # 80021750 <log+0x30>
    80004268:	05c50713          	addi	a4,a0,92
    8000426c:	36fd                	addiw	a3,a3,-1
    8000426e:	1682                	slli	a3,a3,0x20
    80004270:	9281                	srli	a3,a3,0x20
    80004272:	068a                	slli	a3,a3,0x2
    80004274:	0001d617          	auipc	a2,0x1d
    80004278:	4e060613          	addi	a2,a2,1248 # 80021754 <log+0x34>
    8000427c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000427e:	4390                	lw	a2,0(a5)
    80004280:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004282:	0791                	addi	a5,a5,4
    80004284:	0711                	addi	a4,a4,4
    80004286:	fed79ce3          	bne	a5,a3,8000427e <write_head+0x4e>
  }
  bwrite(buf);
    8000428a:	8526                	mv	a0,s1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	09c080e7          	jalr	156(ra) # 80003328 <bwrite>
  brelse(buf);
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	0d0080e7          	jalr	208(ra) # 80003366 <brelse>
}
    8000429e:	60e2                	ld	ra,24(sp)
    800042a0:	6442                	ld	s0,16(sp)
    800042a2:	64a2                	ld	s1,8(sp)
    800042a4:	6902                	ld	s2,0(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret

00000000800042aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042aa:	0001d797          	auipc	a5,0x1d
    800042ae:	4a27a783          	lw	a5,1186(a5) # 8002174c <log+0x2c>
    800042b2:	0af05d63          	blez	a5,8000436c <install_trans+0xc2>
{
    800042b6:	7139                	addi	sp,sp,-64
    800042b8:	fc06                	sd	ra,56(sp)
    800042ba:	f822                	sd	s0,48(sp)
    800042bc:	f426                	sd	s1,40(sp)
    800042be:	f04a                	sd	s2,32(sp)
    800042c0:	ec4e                	sd	s3,24(sp)
    800042c2:	e852                	sd	s4,16(sp)
    800042c4:	e456                	sd	s5,8(sp)
    800042c6:	e05a                	sd	s6,0(sp)
    800042c8:	0080                	addi	s0,sp,64
    800042ca:	8b2a                	mv	s6,a0
    800042cc:	0001da97          	auipc	s5,0x1d
    800042d0:	484a8a93          	addi	s5,s5,1156 # 80021750 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042d6:	0001d997          	auipc	s3,0x1d
    800042da:	44a98993          	addi	s3,s3,1098 # 80021720 <log>
    800042de:	a00d                	j	80004300 <install_trans+0x56>
    brelse(lbuf);
    800042e0:	854a                	mv	a0,s2
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	084080e7          	jalr	132(ra) # 80003366 <brelse>
    brelse(dbuf);
    800042ea:	8526                	mv	a0,s1
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	07a080e7          	jalr	122(ra) # 80003366 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f4:	2a05                	addiw	s4,s4,1
    800042f6:	0a91                	addi	s5,s5,4
    800042f8:	02c9a783          	lw	a5,44(s3)
    800042fc:	04fa5e63          	bge	s4,a5,80004358 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004300:	0189a583          	lw	a1,24(s3)
    80004304:	014585bb          	addw	a1,a1,s4
    80004308:	2585                	addiw	a1,a1,1
    8000430a:	0289a503          	lw	a0,40(s3)
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	f28080e7          	jalr	-216(ra) # 80003236 <bread>
    80004316:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004318:	000aa583          	lw	a1,0(s5)
    8000431c:	0289a503          	lw	a0,40(s3)
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	f16080e7          	jalr	-234(ra) # 80003236 <bread>
    80004328:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000432a:	40000613          	li	a2,1024
    8000432e:	05890593          	addi	a1,s2,88
    80004332:	05850513          	addi	a0,a0,88
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	9f8080e7          	jalr	-1544(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000433e:	8526                	mv	a0,s1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	fe8080e7          	jalr	-24(ra) # 80003328 <bwrite>
    if(recovering == 0)
    80004348:	f80b1ce3          	bnez	s6,800042e0 <install_trans+0x36>
      bunpin(dbuf);
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	0f2080e7          	jalr	242(ra) # 80003440 <bunpin>
    80004356:	b769                	j	800042e0 <install_trans+0x36>
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6aa2                	ld	s5,8(sp)
    80004366:	6b02                	ld	s6,0(sp)
    80004368:	6121                	addi	sp,sp,64
    8000436a:	8082                	ret
    8000436c:	8082                	ret

000000008000436e <initlog>:
{
    8000436e:	7179                	addi	sp,sp,-48
    80004370:	f406                	sd	ra,40(sp)
    80004372:	f022                	sd	s0,32(sp)
    80004374:	ec26                	sd	s1,24(sp)
    80004376:	e84a                	sd	s2,16(sp)
    80004378:	e44e                	sd	s3,8(sp)
    8000437a:	1800                	addi	s0,sp,48
    8000437c:	892a                	mv	s2,a0
    8000437e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004380:	0001d497          	auipc	s1,0x1d
    80004384:	3a048493          	addi	s1,s1,928 # 80021720 <log>
    80004388:	00004597          	auipc	a1,0x4
    8000438c:	2c058593          	addi	a1,a1,704 # 80008648 <syscalls+0x1f8>
    80004390:	8526                	mv	a0,s1
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	7b4080e7          	jalr	1972(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000439a:	0149a583          	lw	a1,20(s3)
    8000439e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043a0:	0109a783          	lw	a5,16(s3)
    800043a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043aa:	854a                	mv	a0,s2
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	e8a080e7          	jalr	-374(ra) # 80003236 <bread>
  log.lh.n = lh->n;
    800043b4:	4d34                	lw	a3,88(a0)
    800043b6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043b8:	02d05563          	blez	a3,800043e2 <initlog+0x74>
    800043bc:	05c50793          	addi	a5,a0,92
    800043c0:	0001d717          	auipc	a4,0x1d
    800043c4:	39070713          	addi	a4,a4,912 # 80021750 <log+0x30>
    800043c8:	36fd                	addiw	a3,a3,-1
    800043ca:	1682                	slli	a3,a3,0x20
    800043cc:	9281                	srli	a3,a3,0x20
    800043ce:	068a                	slli	a3,a3,0x2
    800043d0:	06050613          	addi	a2,a0,96
    800043d4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043d6:	4390                	lw	a2,0(a5)
    800043d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043da:	0791                	addi	a5,a5,4
    800043dc:	0711                	addi	a4,a4,4
    800043de:	fed79ce3          	bne	a5,a3,800043d6 <initlog+0x68>
  brelse(buf);
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	f84080e7          	jalr	-124(ra) # 80003366 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043ea:	4505                	li	a0,1
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	ebe080e7          	jalr	-322(ra) # 800042aa <install_trans>
  log.lh.n = 0;
    800043f4:	0001d797          	auipc	a5,0x1d
    800043f8:	3407ac23          	sw	zero,856(a5) # 8002174c <log+0x2c>
  write_head(); // clear the log
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	e34080e7          	jalr	-460(ra) # 80004230 <write_head>
}
    80004404:	70a2                	ld	ra,40(sp)
    80004406:	7402                	ld	s0,32(sp)
    80004408:	64e2                	ld	s1,24(sp)
    8000440a:	6942                	ld	s2,16(sp)
    8000440c:	69a2                	ld	s3,8(sp)
    8000440e:	6145                	addi	sp,sp,48
    80004410:	8082                	ret

0000000080004412 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000441e:	0001d517          	auipc	a0,0x1d
    80004422:	30250513          	addi	a0,a0,770 # 80021720 <log>
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	7b0080e7          	jalr	1968(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000442e:	0001d497          	auipc	s1,0x1d
    80004432:	2f248493          	addi	s1,s1,754 # 80021720 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004436:	4979                	li	s2,30
    80004438:	a039                	j	80004446 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000443a:	85a6                	mv	a1,s1
    8000443c:	8526                	mv	a0,s1
    8000443e:	ffffe097          	auipc	ra,0xffffe
    80004442:	ca6080e7          	jalr	-858(ra) # 800020e4 <sleep>
    if(log.committing){
    80004446:	50dc                	lw	a5,36(s1)
    80004448:	fbed                	bnez	a5,8000443a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000444a:	509c                	lw	a5,32(s1)
    8000444c:	0017871b          	addiw	a4,a5,1
    80004450:	0007069b          	sext.w	a3,a4
    80004454:	0027179b          	slliw	a5,a4,0x2
    80004458:	9fb9                	addw	a5,a5,a4
    8000445a:	0017979b          	slliw	a5,a5,0x1
    8000445e:	54d8                	lw	a4,44(s1)
    80004460:	9fb9                	addw	a5,a5,a4
    80004462:	00f95963          	bge	s2,a5,80004474 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004466:	85a6                	mv	a1,s1
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffe097          	auipc	ra,0xffffe
    8000446e:	c7a080e7          	jalr	-902(ra) # 800020e4 <sleep>
    80004472:	bfd1                	j	80004446 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004474:	0001d517          	auipc	a0,0x1d
    80004478:	2ac50513          	addi	a0,a0,684 # 80021720 <log>
    8000447c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	80c080e7          	jalr	-2036(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004492:	7139                	addi	sp,sp,-64
    80004494:	fc06                	sd	ra,56(sp)
    80004496:	f822                	sd	s0,48(sp)
    80004498:	f426                	sd	s1,40(sp)
    8000449a:	f04a                	sd	s2,32(sp)
    8000449c:	ec4e                	sd	s3,24(sp)
    8000449e:	e852                	sd	s4,16(sp)
    800044a0:	e456                	sd	s5,8(sp)
    800044a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044a4:	0001d497          	auipc	s1,0x1d
    800044a8:	27c48493          	addi	s1,s1,636 # 80021720 <log>
    800044ac:	8526                	mv	a0,s1
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	728080e7          	jalr	1832(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800044b6:	509c                	lw	a5,32(s1)
    800044b8:	37fd                	addiw	a5,a5,-1
    800044ba:	0007891b          	sext.w	s2,a5
    800044be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044c0:	50dc                	lw	a5,36(s1)
    800044c2:	e7b9                	bnez	a5,80004510 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044c4:	04091e63          	bnez	s2,80004520 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044c8:	0001d497          	auipc	s1,0x1d
    800044cc:	25848493          	addi	s1,s1,600 # 80021720 <log>
    800044d0:	4785                	li	a5,1
    800044d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044de:	54dc                	lw	a5,44(s1)
    800044e0:	06f04763          	bgtz	a5,8000454e <end_op+0xbc>
    acquire(&log.lock);
    800044e4:	0001d497          	auipc	s1,0x1d
    800044e8:	23c48493          	addi	s1,s1,572 # 80021720 <log>
    800044ec:	8526                	mv	a0,s1
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	6e8080e7          	jalr	1768(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	c4c080e7          	jalr	-948(ra) # 80002148 <wakeup>
    release(&log.lock);
    80004504:	8526                	mv	a0,s1
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	784080e7          	jalr	1924(ra) # 80000c8a <release>
}
    8000450e:	a03d                	j	8000453c <end_op+0xaa>
    panic("log.committing");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	14050513          	addi	a0,a0,320 # 80008650 <syscalls+0x200>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	026080e7          	jalr	38(ra) # 8000053e <panic>
    wakeup(&log);
    80004520:	0001d497          	auipc	s1,0x1d
    80004524:	20048493          	addi	s1,s1,512 # 80021720 <log>
    80004528:	8526                	mv	a0,s1
    8000452a:	ffffe097          	auipc	ra,0xffffe
    8000452e:	c1e080e7          	jalr	-994(ra) # 80002148 <wakeup>
  release(&log.lock);
    80004532:	8526                	mv	a0,s1
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	756080e7          	jalr	1878(ra) # 80000c8a <release>
}
    8000453c:	70e2                	ld	ra,56(sp)
    8000453e:	7442                	ld	s0,48(sp)
    80004540:	74a2                	ld	s1,40(sp)
    80004542:	7902                	ld	s2,32(sp)
    80004544:	69e2                	ld	s3,24(sp)
    80004546:	6a42                	ld	s4,16(sp)
    80004548:	6aa2                	ld	s5,8(sp)
    8000454a:	6121                	addi	sp,sp,64
    8000454c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000454e:	0001da97          	auipc	s5,0x1d
    80004552:	202a8a93          	addi	s5,s5,514 # 80021750 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004556:	0001da17          	auipc	s4,0x1d
    8000455a:	1caa0a13          	addi	s4,s4,458 # 80021720 <log>
    8000455e:	018a2583          	lw	a1,24(s4)
    80004562:	012585bb          	addw	a1,a1,s2
    80004566:	2585                	addiw	a1,a1,1
    80004568:	028a2503          	lw	a0,40(s4)
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	cca080e7          	jalr	-822(ra) # 80003236 <bread>
    80004574:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004576:	000aa583          	lw	a1,0(s5)
    8000457a:	028a2503          	lw	a0,40(s4)
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	cb8080e7          	jalr	-840(ra) # 80003236 <bread>
    80004586:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004588:	40000613          	li	a2,1024
    8000458c:	05850593          	addi	a1,a0,88
    80004590:	05848513          	addi	a0,s1,88
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	79a080e7          	jalr	1946(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000459c:	8526                	mv	a0,s1
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	d8a080e7          	jalr	-630(ra) # 80003328 <bwrite>
    brelse(from);
    800045a6:	854e                	mv	a0,s3
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	dbe080e7          	jalr	-578(ra) # 80003366 <brelse>
    brelse(to);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	db4080e7          	jalr	-588(ra) # 80003366 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ba:	2905                	addiw	s2,s2,1
    800045bc:	0a91                	addi	s5,s5,4
    800045be:	02ca2783          	lw	a5,44(s4)
    800045c2:	f8f94ee3          	blt	s2,a5,8000455e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	c6a080e7          	jalr	-918(ra) # 80004230 <write_head>
    install_trans(0); // Now install writes to home locations
    800045ce:	4501                	li	a0,0
    800045d0:	00000097          	auipc	ra,0x0
    800045d4:	cda080e7          	jalr	-806(ra) # 800042aa <install_trans>
    log.lh.n = 0;
    800045d8:	0001d797          	auipc	a5,0x1d
    800045dc:	1607aa23          	sw	zero,372(a5) # 8002174c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	c50080e7          	jalr	-944(ra) # 80004230 <write_head>
    800045e8:	bdf5                	j	800044e4 <end_op+0x52>

00000000800045ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	e04a                	sd	s2,0(sp)
    800045f4:	1000                	addi	s0,sp,32
    800045f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045f8:	0001d917          	auipc	s2,0x1d
    800045fc:	12890913          	addi	s2,s2,296 # 80021720 <log>
    80004600:	854a                	mv	a0,s2
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000460a:	02c92603          	lw	a2,44(s2)
    8000460e:	47f5                	li	a5,29
    80004610:	06c7c563          	blt	a5,a2,8000467a <log_write+0x90>
    80004614:	0001d797          	auipc	a5,0x1d
    80004618:	1287a783          	lw	a5,296(a5) # 8002173c <log+0x1c>
    8000461c:	37fd                	addiw	a5,a5,-1
    8000461e:	04f65e63          	bge	a2,a5,8000467a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004622:	0001d797          	auipc	a5,0x1d
    80004626:	11e7a783          	lw	a5,286(a5) # 80021740 <log+0x20>
    8000462a:	06f05063          	blez	a5,8000468a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000462e:	4781                	li	a5,0
    80004630:	06c05563          	blez	a2,8000469a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004634:	44cc                	lw	a1,12(s1)
    80004636:	0001d717          	auipc	a4,0x1d
    8000463a:	11a70713          	addi	a4,a4,282 # 80021750 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000463e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004640:	4314                	lw	a3,0(a4)
    80004642:	04b68c63          	beq	a3,a1,8000469a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004646:	2785                	addiw	a5,a5,1
    80004648:	0711                	addi	a4,a4,4
    8000464a:	fef61be3          	bne	a2,a5,80004640 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000464e:	0621                	addi	a2,a2,8
    80004650:	060a                	slli	a2,a2,0x2
    80004652:	0001d797          	auipc	a5,0x1d
    80004656:	0ce78793          	addi	a5,a5,206 # 80021720 <log>
    8000465a:	963e                	add	a2,a2,a5
    8000465c:	44dc                	lw	a5,12(s1)
    8000465e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004660:	8526                	mv	a0,s1
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	da2080e7          	jalr	-606(ra) # 80003404 <bpin>
    log.lh.n++;
    8000466a:	0001d717          	auipc	a4,0x1d
    8000466e:	0b670713          	addi	a4,a4,182 # 80021720 <log>
    80004672:	575c                	lw	a5,44(a4)
    80004674:	2785                	addiw	a5,a5,1
    80004676:	d75c                	sw	a5,44(a4)
    80004678:	a835                	j	800046b4 <log_write+0xca>
    panic("too big a transaction");
    8000467a:	00004517          	auipc	a0,0x4
    8000467e:	fe650513          	addi	a0,a0,-26 # 80008660 <syscalls+0x210>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000468a:	00004517          	auipc	a0,0x4
    8000468e:	fee50513          	addi	a0,a0,-18 # 80008678 <syscalls+0x228>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000469a:	00878713          	addi	a4,a5,8
    8000469e:	00271693          	slli	a3,a4,0x2
    800046a2:	0001d717          	auipc	a4,0x1d
    800046a6:	07e70713          	addi	a4,a4,126 # 80021720 <log>
    800046aa:	9736                	add	a4,a4,a3
    800046ac:	44d4                	lw	a3,12(s1)
    800046ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046b0:	faf608e3          	beq	a2,a5,80004660 <log_write+0x76>
  }
  release(&log.lock);
    800046b4:	0001d517          	auipc	a0,0x1d
    800046b8:	06c50513          	addi	a0,a0,108 # 80021720 <log>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5ce080e7          	jalr	1486(ra) # 80000c8a <release>
}
    800046c4:	60e2                	ld	ra,24(sp)
    800046c6:	6442                	ld	s0,16(sp)
    800046c8:	64a2                	ld	s1,8(sp)
    800046ca:	6902                	ld	s2,0(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
    800046de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046e0:	00004597          	auipc	a1,0x4
    800046e4:	fb858593          	addi	a1,a1,-72 # 80008698 <syscalls+0x248>
    800046e8:	0521                	addi	a0,a0,8
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	45c080e7          	jalr	1116(ra) # 80000b46 <initlock>
  lk->name = name;
    800046f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046fa:	0204a423          	sw	zero,40(s1)
}
    800046fe:	60e2                	ld	ra,24(sp)
    80004700:	6442                	ld	s0,16(sp)
    80004702:	64a2                	ld	s1,8(sp)
    80004704:	6902                	ld	s2,0(sp)
    80004706:	6105                	addi	sp,sp,32
    80004708:	8082                	ret

000000008000470a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000470a:	1101                	addi	sp,sp,-32
    8000470c:	ec06                	sd	ra,24(sp)
    8000470e:	e822                	sd	s0,16(sp)
    80004710:	e426                	sd	s1,8(sp)
    80004712:	e04a                	sd	s2,0(sp)
    80004714:	1000                	addi	s0,sp,32
    80004716:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004718:	00850913          	addi	s2,a0,8
    8000471c:	854a                	mv	a0,s2
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	4b8080e7          	jalr	1208(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004726:	409c                	lw	a5,0(s1)
    80004728:	cb89                	beqz	a5,8000473a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000472a:	85ca                	mv	a1,s2
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffe097          	auipc	ra,0xffffe
    80004732:	9b6080e7          	jalr	-1610(ra) # 800020e4 <sleep>
  while (lk->locked) {
    80004736:	409c                	lw	a5,0(s1)
    80004738:	fbed                	bnez	a5,8000472a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000473a:	4785                	li	a5,1
    8000473c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000473e:	ffffd097          	auipc	ra,0xffffd
    80004742:	26e080e7          	jalr	622(ra) # 800019ac <myproc>
    80004746:	591c                	lw	a5,48(a0)
    80004748:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000474a:	854a                	mv	a0,s2
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	53e080e7          	jalr	1342(ra) # 80000c8a <release>
}
    80004754:	60e2                	ld	ra,24(sp)
    80004756:	6442                	ld	s0,16(sp)
    80004758:	64a2                	ld	s1,8(sp)
    8000475a:	6902                	ld	s2,0(sp)
    8000475c:	6105                	addi	sp,sp,32
    8000475e:	8082                	ret

0000000080004760 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004760:	1101                	addi	sp,sp,-32
    80004762:	ec06                	sd	ra,24(sp)
    80004764:	e822                	sd	s0,16(sp)
    80004766:	e426                	sd	s1,8(sp)
    80004768:	e04a                	sd	s2,0(sp)
    8000476a:	1000                	addi	s0,sp,32
    8000476c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000476e:	00850913          	addi	s2,a0,8
    80004772:	854a                	mv	a0,s2
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	462080e7          	jalr	1122(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000477c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004780:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004784:	8526                	mv	a0,s1
    80004786:	ffffe097          	auipc	ra,0xffffe
    8000478a:	9c2080e7          	jalr	-1598(ra) # 80002148 <wakeup>
  release(&lk->lk);
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
}
    80004798:	60e2                	ld	ra,24(sp)
    8000479a:	6442                	ld	s0,16(sp)
    8000479c:	64a2                	ld	s1,8(sp)
    8000479e:	6902                	ld	s2,0(sp)
    800047a0:	6105                	addi	sp,sp,32
    800047a2:	8082                	ret

00000000800047a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047a4:	7179                	addi	sp,sp,-48
    800047a6:	f406                	sd	ra,40(sp)
    800047a8:	f022                	sd	s0,32(sp)
    800047aa:	ec26                	sd	s1,24(sp)
    800047ac:	e84a                	sd	s2,16(sp)
    800047ae:	e44e                	sd	s3,8(sp)
    800047b0:	1800                	addi	s0,sp,48
    800047b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047b4:	00850913          	addi	s2,a0,8
    800047b8:	854a                	mv	a0,s2
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	41c080e7          	jalr	1052(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047c2:	409c                	lw	a5,0(s1)
    800047c4:	ef99                	bnez	a5,800047e2 <holdingsleep+0x3e>
    800047c6:	4481                	li	s1,0
  release(&lk->lk);
    800047c8:	854a                	mv	a0,s2
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	4c0080e7          	jalr	1216(ra) # 80000c8a <release>
  return r;
}
    800047d2:	8526                	mv	a0,s1
    800047d4:	70a2                	ld	ra,40(sp)
    800047d6:	7402                	ld	s0,32(sp)
    800047d8:	64e2                	ld	s1,24(sp)
    800047da:	6942                	ld	s2,16(sp)
    800047dc:	69a2                	ld	s3,8(sp)
    800047de:	6145                	addi	sp,sp,48
    800047e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047e2:	0284a983          	lw	s3,40(s1)
    800047e6:	ffffd097          	auipc	ra,0xffffd
    800047ea:	1c6080e7          	jalr	454(ra) # 800019ac <myproc>
    800047ee:	5904                	lw	s1,48(a0)
    800047f0:	413484b3          	sub	s1,s1,s3
    800047f4:	0014b493          	seqz	s1,s1
    800047f8:	bfc1                	j	800047c8 <holdingsleep+0x24>

00000000800047fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047fa:	1141                	addi	sp,sp,-16
    800047fc:	e406                	sd	ra,8(sp)
    800047fe:	e022                	sd	s0,0(sp)
    80004800:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004802:	00004597          	auipc	a1,0x4
    80004806:	ea658593          	addi	a1,a1,-346 # 800086a8 <syscalls+0x258>
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	05e50513          	addi	a0,a0,94 # 80021868 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	334080e7          	jalr	820(ra) # 80000b46 <initlock>
}
    8000481a:	60a2                	ld	ra,8(sp)
    8000481c:	6402                	ld	s0,0(sp)
    8000481e:	0141                	addi	sp,sp,16
    80004820:	8082                	ret

0000000080004822 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004822:	1101                	addi	sp,sp,-32
    80004824:	ec06                	sd	ra,24(sp)
    80004826:	e822                	sd	s0,16(sp)
    80004828:	e426                	sd	s1,8(sp)
    8000482a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000482c:	0001d517          	auipc	a0,0x1d
    80004830:	03c50513          	addi	a0,a0,60 # 80021868 <ftable>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	3a2080e7          	jalr	930(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000483c:	0001d497          	auipc	s1,0x1d
    80004840:	04448493          	addi	s1,s1,68 # 80021880 <ftable+0x18>
    80004844:	0001e717          	auipc	a4,0x1e
    80004848:	fdc70713          	addi	a4,a4,-36 # 80022820 <disk>
    if(f->ref == 0){
    8000484c:	40dc                	lw	a5,4(s1)
    8000484e:	cf99                	beqz	a5,8000486c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004850:	02848493          	addi	s1,s1,40
    80004854:	fee49ce3          	bne	s1,a4,8000484c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004858:	0001d517          	auipc	a0,0x1d
    8000485c:	01050513          	addi	a0,a0,16 # 80021868 <ftable>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	42a080e7          	jalr	1066(ra) # 80000c8a <release>
  return 0;
    80004868:	4481                	li	s1,0
    8000486a:	a819                	j	80004880 <filealloc+0x5e>
      f->ref = 1;
    8000486c:	4785                	li	a5,1
    8000486e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004870:	0001d517          	auipc	a0,0x1d
    80004874:	ff850513          	addi	a0,a0,-8 # 80021868 <ftable>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	412080e7          	jalr	1042(ra) # 80000c8a <release>
}
    80004880:	8526                	mv	a0,s1
    80004882:	60e2                	ld	ra,24(sp)
    80004884:	6442                	ld	s0,16(sp)
    80004886:	64a2                	ld	s1,8(sp)
    80004888:	6105                	addi	sp,sp,32
    8000488a:	8082                	ret

000000008000488c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000488c:	1101                	addi	sp,sp,-32
    8000488e:	ec06                	sd	ra,24(sp)
    80004890:	e822                	sd	s0,16(sp)
    80004892:	e426                	sd	s1,8(sp)
    80004894:	1000                	addi	s0,sp,32
    80004896:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004898:	0001d517          	auipc	a0,0x1d
    8000489c:	fd050513          	addi	a0,a0,-48 # 80021868 <ftable>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	336080e7          	jalr	822(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048a8:	40dc                	lw	a5,4(s1)
    800048aa:	02f05263          	blez	a5,800048ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048ae:	2785                	addiw	a5,a5,1
    800048b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048b2:	0001d517          	auipc	a0,0x1d
    800048b6:	fb650513          	addi	a0,a0,-74 # 80021868 <ftable>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	3d0080e7          	jalr	976(ra) # 80000c8a <release>
  return f;
}
    800048c2:	8526                	mv	a0,s1
    800048c4:	60e2                	ld	ra,24(sp)
    800048c6:	6442                	ld	s0,16(sp)
    800048c8:	64a2                	ld	s1,8(sp)
    800048ca:	6105                	addi	sp,sp,32
    800048cc:	8082                	ret
    panic("filedup");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	de250513          	addi	a0,a0,-542 # 800086b0 <syscalls+0x260>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>

00000000800048de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048de:	7139                	addi	sp,sp,-64
    800048e0:	fc06                	sd	ra,56(sp)
    800048e2:	f822                	sd	s0,48(sp)
    800048e4:	f426                	sd	s1,40(sp)
    800048e6:	f04a                	sd	s2,32(sp)
    800048e8:	ec4e                	sd	s3,24(sp)
    800048ea:	e852                	sd	s4,16(sp)
    800048ec:	e456                	sd	s5,8(sp)
    800048ee:	0080                	addi	s0,sp,64
    800048f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	f7650513          	addi	a0,a0,-138 # 80021868 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	2dc080e7          	jalr	732(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004902:	40dc                	lw	a5,4(s1)
    80004904:	06f05163          	blez	a5,80004966 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004908:	37fd                	addiw	a5,a5,-1
    8000490a:	0007871b          	sext.w	a4,a5
    8000490e:	c0dc                	sw	a5,4(s1)
    80004910:	06e04363          	bgtz	a4,80004976 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004914:	0004a903          	lw	s2,0(s1)
    80004918:	0094ca83          	lbu	s5,9(s1)
    8000491c:	0104ba03          	ld	s4,16(s1)
    80004920:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004924:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004928:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000492c:	0001d517          	auipc	a0,0x1d
    80004930:	f3c50513          	addi	a0,a0,-196 # 80021868 <ftable>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	356080e7          	jalr	854(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000493c:	4785                	li	a5,1
    8000493e:	04f90d63          	beq	s2,a5,80004998 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004942:	3979                	addiw	s2,s2,-2
    80004944:	4785                	li	a5,1
    80004946:	0527e063          	bltu	a5,s2,80004986 <fileclose+0xa8>
    begin_op();
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	ac8080e7          	jalr	-1336(ra) # 80004412 <begin_op>
    iput(ff.ip);
    80004952:	854e                	mv	a0,s3
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	2b6080e7          	jalr	694(ra) # 80003c0a <iput>
    end_op();
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	b36080e7          	jalr	-1226(ra) # 80004492 <end_op>
    80004964:	a00d                	j	80004986 <fileclose+0xa8>
    panic("fileclose");
    80004966:	00004517          	auipc	a0,0x4
    8000496a:	d5250513          	addi	a0,a0,-686 # 800086b8 <syscalls+0x268>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004976:	0001d517          	auipc	a0,0x1d
    8000497a:	ef250513          	addi	a0,a0,-270 # 80021868 <ftable>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	30c080e7          	jalr	780(ra) # 80000c8a <release>
  }
}
    80004986:	70e2                	ld	ra,56(sp)
    80004988:	7442                	ld	s0,48(sp)
    8000498a:	74a2                	ld	s1,40(sp)
    8000498c:	7902                	ld	s2,32(sp)
    8000498e:	69e2                	ld	s3,24(sp)
    80004990:	6a42                	ld	s4,16(sp)
    80004992:	6aa2                	ld	s5,8(sp)
    80004994:	6121                	addi	sp,sp,64
    80004996:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004998:	85d6                	mv	a1,s5
    8000499a:	8552                	mv	a0,s4
    8000499c:	00000097          	auipc	ra,0x0
    800049a0:	34c080e7          	jalr	844(ra) # 80004ce8 <pipeclose>
    800049a4:	b7cd                	j	80004986 <fileclose+0xa8>

00000000800049a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049a6:	715d                	addi	sp,sp,-80
    800049a8:	e486                	sd	ra,72(sp)
    800049aa:	e0a2                	sd	s0,64(sp)
    800049ac:	fc26                	sd	s1,56(sp)
    800049ae:	f84a                	sd	s2,48(sp)
    800049b0:	f44e                	sd	s3,40(sp)
    800049b2:	0880                	addi	s0,sp,80
    800049b4:	84aa                	mv	s1,a0
    800049b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049b8:	ffffd097          	auipc	ra,0xffffd
    800049bc:	ff4080e7          	jalr	-12(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049c0:	409c                	lw	a5,0(s1)
    800049c2:	37f9                	addiw	a5,a5,-2
    800049c4:	4705                	li	a4,1
    800049c6:	04f76763          	bltu	a4,a5,80004a14 <filestat+0x6e>
    800049ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800049cc:	6c88                	ld	a0,24(s1)
    800049ce:	fffff097          	auipc	ra,0xfffff
    800049d2:	082080e7          	jalr	130(ra) # 80003a50 <ilock>
    stati(f->ip, &st);
    800049d6:	fb840593          	addi	a1,s0,-72
    800049da:	6c88                	ld	a0,24(s1)
    800049dc:	fffff097          	auipc	ra,0xfffff
    800049e0:	2fe080e7          	jalr	766(ra) # 80003cda <stati>
    iunlock(f->ip);
    800049e4:	6c88                	ld	a0,24(s1)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	12c080e7          	jalr	300(ra) # 80003b12 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ee:	46e1                	li	a3,24
    800049f0:	fb840613          	addi	a2,s0,-72
    800049f4:	85ce                	mv	a1,s3
    800049f6:	05893503          	ld	a0,88(s2)
    800049fa:	ffffd097          	auipc	ra,0xffffd
    800049fe:	c6e080e7          	jalr	-914(ra) # 80001668 <copyout>
    80004a02:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a06:	60a6                	ld	ra,72(sp)
    80004a08:	6406                	ld	s0,64(sp)
    80004a0a:	74e2                	ld	s1,56(sp)
    80004a0c:	7942                	ld	s2,48(sp)
    80004a0e:	79a2                	ld	s3,40(sp)
    80004a10:	6161                	addi	sp,sp,80
    80004a12:	8082                	ret
  return -1;
    80004a14:	557d                	li	a0,-1
    80004a16:	bfc5                	j	80004a06 <filestat+0x60>

0000000080004a18 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a18:	7179                	addi	sp,sp,-48
    80004a1a:	f406                	sd	ra,40(sp)
    80004a1c:	f022                	sd	s0,32(sp)
    80004a1e:	ec26                	sd	s1,24(sp)
    80004a20:	e84a                	sd	s2,16(sp)
    80004a22:	e44e                	sd	s3,8(sp)
    80004a24:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a26:	00854783          	lbu	a5,8(a0)
    80004a2a:	c3d5                	beqz	a5,80004ace <fileread+0xb6>
    80004a2c:	84aa                	mv	s1,a0
    80004a2e:	89ae                	mv	s3,a1
    80004a30:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a32:	411c                	lw	a5,0(a0)
    80004a34:	4705                	li	a4,1
    80004a36:	04e78963          	beq	a5,a4,80004a88 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3a:	470d                	li	a4,3
    80004a3c:	04e78d63          	beq	a5,a4,80004a96 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a40:	4709                	li	a4,2
    80004a42:	06e79e63          	bne	a5,a4,80004abe <fileread+0xa6>
    ilock(f->ip);
    80004a46:	6d08                	ld	a0,24(a0)
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	008080e7          	jalr	8(ra) # 80003a50 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a50:	874a                	mv	a4,s2
    80004a52:	5094                	lw	a3,32(s1)
    80004a54:	864e                	mv	a2,s3
    80004a56:	4585                	li	a1,1
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	2aa080e7          	jalr	682(ra) # 80003d04 <readi>
    80004a62:	892a                	mv	s2,a0
    80004a64:	00a05563          	blez	a0,80004a6e <fileread+0x56>
      f->off += r;
    80004a68:	509c                	lw	a5,32(s1)
    80004a6a:	9fa9                	addw	a5,a5,a0
    80004a6c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a6e:	6c88                	ld	a0,24(s1)
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	0a2080e7          	jalr	162(ra) # 80003b12 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a78:	854a                	mv	a0,s2
    80004a7a:	70a2                	ld	ra,40(sp)
    80004a7c:	7402                	ld	s0,32(sp)
    80004a7e:	64e2                	ld	s1,24(sp)
    80004a80:	6942                	ld	s2,16(sp)
    80004a82:	69a2                	ld	s3,8(sp)
    80004a84:	6145                	addi	sp,sp,48
    80004a86:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a88:	6908                	ld	a0,16(a0)
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	3c6080e7          	jalr	966(ra) # 80004e50 <piperead>
    80004a92:	892a                	mv	s2,a0
    80004a94:	b7d5                	j	80004a78 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a96:	02451783          	lh	a5,36(a0)
    80004a9a:	03079693          	slli	a3,a5,0x30
    80004a9e:	92c1                	srli	a3,a3,0x30
    80004aa0:	4725                	li	a4,9
    80004aa2:	02d76863          	bltu	a4,a3,80004ad2 <fileread+0xba>
    80004aa6:	0792                	slli	a5,a5,0x4
    80004aa8:	0001d717          	auipc	a4,0x1d
    80004aac:	d2070713          	addi	a4,a4,-736 # 800217c8 <devsw>
    80004ab0:	97ba                	add	a5,a5,a4
    80004ab2:	639c                	ld	a5,0(a5)
    80004ab4:	c38d                	beqz	a5,80004ad6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ab6:	4505                	li	a0,1
    80004ab8:	9782                	jalr	a5
    80004aba:	892a                	mv	s2,a0
    80004abc:	bf75                	j	80004a78 <fileread+0x60>
    panic("fileread");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	c0a50513          	addi	a0,a0,-1014 # 800086c8 <syscalls+0x278>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a78080e7          	jalr	-1416(ra) # 8000053e <panic>
    return -1;
    80004ace:	597d                	li	s2,-1
    80004ad0:	b765                	j	80004a78 <fileread+0x60>
      return -1;
    80004ad2:	597d                	li	s2,-1
    80004ad4:	b755                	j	80004a78 <fileread+0x60>
    80004ad6:	597d                	li	s2,-1
    80004ad8:	b745                	j	80004a78 <fileread+0x60>

0000000080004ada <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ada:	715d                	addi	sp,sp,-80
    80004adc:	e486                	sd	ra,72(sp)
    80004ade:	e0a2                	sd	s0,64(sp)
    80004ae0:	fc26                	sd	s1,56(sp)
    80004ae2:	f84a                	sd	s2,48(sp)
    80004ae4:	f44e                	sd	s3,40(sp)
    80004ae6:	f052                	sd	s4,32(sp)
    80004ae8:	ec56                	sd	s5,24(sp)
    80004aea:	e85a                	sd	s6,16(sp)
    80004aec:	e45e                	sd	s7,8(sp)
    80004aee:	e062                	sd	s8,0(sp)
    80004af0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004af2:	00954783          	lbu	a5,9(a0)
    80004af6:	10078663          	beqz	a5,80004c02 <filewrite+0x128>
    80004afa:	892a                	mv	s2,a0
    80004afc:	8aae                	mv	s5,a1
    80004afe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b00:	411c                	lw	a5,0(a0)
    80004b02:	4705                	li	a4,1
    80004b04:	02e78263          	beq	a5,a4,80004b28 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b08:	470d                	li	a4,3
    80004b0a:	02e78663          	beq	a5,a4,80004b36 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0e:	4709                	li	a4,2
    80004b10:	0ee79163          	bne	a5,a4,80004bf2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b14:	0ac05d63          	blez	a2,80004bce <filewrite+0xf4>
    int i = 0;
    80004b18:	4981                	li	s3,0
    80004b1a:	6b05                	lui	s6,0x1
    80004b1c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b20:	6b85                	lui	s7,0x1
    80004b22:	c00b8b9b          	addiw	s7,s7,-1024
    80004b26:	a861                	j	80004bbe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b28:	6908                	ld	a0,16(a0)
    80004b2a:	00000097          	auipc	ra,0x0
    80004b2e:	22e080e7          	jalr	558(ra) # 80004d58 <pipewrite>
    80004b32:	8a2a                	mv	s4,a0
    80004b34:	a045                	j	80004bd4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b36:	02451783          	lh	a5,36(a0)
    80004b3a:	03079693          	slli	a3,a5,0x30
    80004b3e:	92c1                	srli	a3,a3,0x30
    80004b40:	4725                	li	a4,9
    80004b42:	0cd76263          	bltu	a4,a3,80004c06 <filewrite+0x12c>
    80004b46:	0792                	slli	a5,a5,0x4
    80004b48:	0001d717          	auipc	a4,0x1d
    80004b4c:	c8070713          	addi	a4,a4,-896 # 800217c8 <devsw>
    80004b50:	97ba                	add	a5,a5,a4
    80004b52:	679c                	ld	a5,8(a5)
    80004b54:	cbdd                	beqz	a5,80004c0a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b56:	4505                	li	a0,1
    80004b58:	9782                	jalr	a5
    80004b5a:	8a2a                	mv	s4,a0
    80004b5c:	a8a5                	j	80004bd4 <filewrite+0xfa>
    80004b5e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	8b0080e7          	jalr	-1872(ra) # 80004412 <begin_op>
      ilock(f->ip);
    80004b6a:	01893503          	ld	a0,24(s2)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	ee2080e7          	jalr	-286(ra) # 80003a50 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b76:	8762                	mv	a4,s8
    80004b78:	02092683          	lw	a3,32(s2)
    80004b7c:	01598633          	add	a2,s3,s5
    80004b80:	4585                	li	a1,1
    80004b82:	01893503          	ld	a0,24(s2)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	276080e7          	jalr	630(ra) # 80003dfc <writei>
    80004b8e:	84aa                	mv	s1,a0
    80004b90:	00a05763          	blez	a0,80004b9e <filewrite+0xc4>
        f->off += r;
    80004b94:	02092783          	lw	a5,32(s2)
    80004b98:	9fa9                	addw	a5,a5,a0
    80004b9a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b9e:	01893503          	ld	a0,24(s2)
    80004ba2:	fffff097          	auipc	ra,0xfffff
    80004ba6:	f70080e7          	jalr	-144(ra) # 80003b12 <iunlock>
      end_op();
    80004baa:	00000097          	auipc	ra,0x0
    80004bae:	8e8080e7          	jalr	-1816(ra) # 80004492 <end_op>

      if(r != n1){
    80004bb2:	009c1f63          	bne	s8,s1,80004bd0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bb6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bba:	0149db63          	bge	s3,s4,80004bd0 <filewrite+0xf6>
      int n1 = n - i;
    80004bbe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bc2:	84be                	mv	s1,a5
    80004bc4:	2781                	sext.w	a5,a5
    80004bc6:	f8fb5ce3          	bge	s6,a5,80004b5e <filewrite+0x84>
    80004bca:	84de                	mv	s1,s7
    80004bcc:	bf49                	j	80004b5e <filewrite+0x84>
    int i = 0;
    80004bce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bd0:	013a1f63          	bne	s4,s3,80004bee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bd4:	8552                	mv	a0,s4
    80004bd6:	60a6                	ld	ra,72(sp)
    80004bd8:	6406                	ld	s0,64(sp)
    80004bda:	74e2                	ld	s1,56(sp)
    80004bdc:	7942                	ld	s2,48(sp)
    80004bde:	79a2                	ld	s3,40(sp)
    80004be0:	7a02                	ld	s4,32(sp)
    80004be2:	6ae2                	ld	s5,24(sp)
    80004be4:	6b42                	ld	s6,16(sp)
    80004be6:	6ba2                	ld	s7,8(sp)
    80004be8:	6c02                	ld	s8,0(sp)
    80004bea:	6161                	addi	sp,sp,80
    80004bec:	8082                	ret
    ret = (i == n ? n : -1);
    80004bee:	5a7d                	li	s4,-1
    80004bf0:	b7d5                	j	80004bd4 <filewrite+0xfa>
    panic("filewrite");
    80004bf2:	00004517          	auipc	a0,0x4
    80004bf6:	ae650513          	addi	a0,a0,-1306 # 800086d8 <syscalls+0x288>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	944080e7          	jalr	-1724(ra) # 8000053e <panic>
    return -1;
    80004c02:	5a7d                	li	s4,-1
    80004c04:	bfc1                	j	80004bd4 <filewrite+0xfa>
      return -1;
    80004c06:	5a7d                	li	s4,-1
    80004c08:	b7f1                	j	80004bd4 <filewrite+0xfa>
    80004c0a:	5a7d                	li	s4,-1
    80004c0c:	b7e1                	j	80004bd4 <filewrite+0xfa>

0000000080004c0e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c0e:	7179                	addi	sp,sp,-48
    80004c10:	f406                	sd	ra,40(sp)
    80004c12:	f022                	sd	s0,32(sp)
    80004c14:	ec26                	sd	s1,24(sp)
    80004c16:	e84a                	sd	s2,16(sp)
    80004c18:	e44e                	sd	s3,8(sp)
    80004c1a:	e052                	sd	s4,0(sp)
    80004c1c:	1800                	addi	s0,sp,48
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c22:	0005b023          	sd	zero,0(a1)
    80004c26:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	bf8080e7          	jalr	-1032(ra) # 80004822 <filealloc>
    80004c32:	e088                	sd	a0,0(s1)
    80004c34:	c551                	beqz	a0,80004cc0 <pipealloc+0xb2>
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	bec080e7          	jalr	-1044(ra) # 80004822 <filealloc>
    80004c3e:	00aa3023          	sd	a0,0(s4)
    80004c42:	c92d                	beqz	a0,80004cb4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	ea2080e7          	jalr	-350(ra) # 80000ae6 <kalloc>
    80004c4c:	892a                	mv	s2,a0
    80004c4e:	c125                	beqz	a0,80004cae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c50:	4985                	li	s3,1
    80004c52:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c56:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c5a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c5e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c62:	00004597          	auipc	a1,0x4
    80004c66:	a8658593          	addi	a1,a1,-1402 # 800086e8 <syscalls+0x298>
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	edc080e7          	jalr	-292(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c72:	609c                	ld	a5,0(s1)
    80004c74:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c78:	609c                	ld	a5,0(s1)
    80004c7a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c7e:	609c                	ld	a5,0(s1)
    80004c80:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c84:	609c                	ld	a5,0(s1)
    80004c86:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c8a:	000a3783          	ld	a5,0(s4)
    80004c8e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c92:	000a3783          	ld	a5,0(s4)
    80004c96:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c9a:	000a3783          	ld	a5,0(s4)
    80004c9e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ca2:	000a3783          	ld	a5,0(s4)
    80004ca6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004caa:	4501                	li	a0,0
    80004cac:	a025                	j	80004cd4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cae:	6088                	ld	a0,0(s1)
    80004cb0:	e501                	bnez	a0,80004cb8 <pipealloc+0xaa>
    80004cb2:	a039                	j	80004cc0 <pipealloc+0xb2>
    80004cb4:	6088                	ld	a0,0(s1)
    80004cb6:	c51d                	beqz	a0,80004ce4 <pipealloc+0xd6>
    fileclose(*f0);
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	c26080e7          	jalr	-986(ra) # 800048de <fileclose>
  if(*f1)
    80004cc0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cc4:	557d                	li	a0,-1
  if(*f1)
    80004cc6:	c799                	beqz	a5,80004cd4 <pipealloc+0xc6>
    fileclose(*f1);
    80004cc8:	853e                	mv	a0,a5
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	c14080e7          	jalr	-1004(ra) # 800048de <fileclose>
  return -1;
    80004cd2:	557d                	li	a0,-1
}
    80004cd4:	70a2                	ld	ra,40(sp)
    80004cd6:	7402                	ld	s0,32(sp)
    80004cd8:	64e2                	ld	s1,24(sp)
    80004cda:	6942                	ld	s2,16(sp)
    80004cdc:	69a2                	ld	s3,8(sp)
    80004cde:	6a02                	ld	s4,0(sp)
    80004ce0:	6145                	addi	sp,sp,48
    80004ce2:	8082                	ret
  return -1;
    80004ce4:	557d                	li	a0,-1
    80004ce6:	b7fd                	j	80004cd4 <pipealloc+0xc6>

0000000080004ce8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ce8:	1101                	addi	sp,sp,-32
    80004cea:	ec06                	sd	ra,24(sp)
    80004cec:	e822                	sd	s0,16(sp)
    80004cee:	e426                	sd	s1,8(sp)
    80004cf0:	e04a                	sd	s2,0(sp)
    80004cf2:	1000                	addi	s0,sp,32
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	ede080e7          	jalr	-290(ra) # 80000bd6 <acquire>
  if(writable){
    80004d00:	02090d63          	beqz	s2,80004d3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004d04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d08:	21848513          	addi	a0,s1,536
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	43c080e7          	jalr	1084(ra) # 80002148 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d14:	2204b783          	ld	a5,544(s1)
    80004d18:	eb95                	bnez	a5,80004d4c <pipeclose+0x64>
    release(&pi->lock);
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	f6e080e7          	jalr	-146(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	cc4080e7          	jalr	-828(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004d2e:	60e2                	ld	ra,24(sp)
    80004d30:	6442                	ld	s0,16(sp)
    80004d32:	64a2                	ld	s1,8(sp)
    80004d34:	6902                	ld	s2,0(sp)
    80004d36:	6105                	addi	sp,sp,32
    80004d38:	8082                	ret
    pi->readopen = 0;
    80004d3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d3e:	21c48513          	addi	a0,s1,540
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	406080e7          	jalr	1030(ra) # 80002148 <wakeup>
    80004d4a:	b7e9                	j	80004d14 <pipeclose+0x2c>
    release(&pi->lock);
    80004d4c:	8526                	mv	a0,s1
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f3c080e7          	jalr	-196(ra) # 80000c8a <release>
}
    80004d56:	bfe1                	j	80004d2e <pipeclose+0x46>

0000000080004d58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d58:	711d                	addi	sp,sp,-96
    80004d5a:	ec86                	sd	ra,88(sp)
    80004d5c:	e8a2                	sd	s0,80(sp)
    80004d5e:	e4a6                	sd	s1,72(sp)
    80004d60:	e0ca                	sd	s2,64(sp)
    80004d62:	fc4e                	sd	s3,56(sp)
    80004d64:	f852                	sd	s4,48(sp)
    80004d66:	f456                	sd	s5,40(sp)
    80004d68:	f05a                	sd	s6,32(sp)
    80004d6a:	ec5e                	sd	s7,24(sp)
    80004d6c:	e862                	sd	s8,16(sp)
    80004d6e:	1080                	addi	s0,sp,96
    80004d70:	84aa                	mv	s1,a0
    80004d72:	8aae                	mv	s5,a1
    80004d74:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	c36080e7          	jalr	-970(ra) # 800019ac <myproc>
    80004d7e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	e54080e7          	jalr	-428(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d8a:	0b405663          	blez	s4,80004e36 <pipewrite+0xde>
  int i = 0;
    80004d8e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d90:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d92:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d96:	21c48b93          	addi	s7,s1,540
    80004d9a:	a089                	j	80004ddc <pipewrite+0x84>
      release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	eec080e7          	jalr	-276(ra) # 80000c8a <release>
      return -1;
    80004da6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004da8:	854a                	mv	a0,s2
    80004daa:	60e6                	ld	ra,88(sp)
    80004dac:	6446                	ld	s0,80(sp)
    80004dae:	64a6                	ld	s1,72(sp)
    80004db0:	6906                	ld	s2,64(sp)
    80004db2:	79e2                	ld	s3,56(sp)
    80004db4:	7a42                	ld	s4,48(sp)
    80004db6:	7aa2                	ld	s5,40(sp)
    80004db8:	7b02                	ld	s6,32(sp)
    80004dba:	6be2                	ld	s7,24(sp)
    80004dbc:	6c42                	ld	s8,16(sp)
    80004dbe:	6125                	addi	sp,sp,96
    80004dc0:	8082                	ret
      wakeup(&pi->nread);
    80004dc2:	8562                	mv	a0,s8
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	384080e7          	jalr	900(ra) # 80002148 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dcc:	85a6                	mv	a1,s1
    80004dce:	855e                	mv	a0,s7
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	314080e7          	jalr	788(ra) # 800020e4 <sleep>
  while(i < n){
    80004dd8:	07495063          	bge	s2,s4,80004e38 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ddc:	2204a783          	lw	a5,544(s1)
    80004de0:	dfd5                	beqz	a5,80004d9c <pipewrite+0x44>
    80004de2:	854e                	mv	a0,s3
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	5b4080e7          	jalr	1460(ra) # 80002398 <killed>
    80004dec:	f945                	bnez	a0,80004d9c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dee:	2184a783          	lw	a5,536(s1)
    80004df2:	21c4a703          	lw	a4,540(s1)
    80004df6:	2007879b          	addiw	a5,a5,512
    80004dfa:	fcf704e3          	beq	a4,a5,80004dc2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dfe:	4685                	li	a3,1
    80004e00:	01590633          	add	a2,s2,s5
    80004e04:	faf40593          	addi	a1,s0,-81
    80004e08:	0589b503          	ld	a0,88(s3)
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	8e8080e7          	jalr	-1816(ra) # 800016f4 <copyin>
    80004e14:	03650263          	beq	a0,s6,80004e38 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e18:	21c4a783          	lw	a5,540(s1)
    80004e1c:	0017871b          	addiw	a4,a5,1
    80004e20:	20e4ae23          	sw	a4,540(s1)
    80004e24:	1ff7f793          	andi	a5,a5,511
    80004e28:	97a6                	add	a5,a5,s1
    80004e2a:	faf44703          	lbu	a4,-81(s0)
    80004e2e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e32:	2905                	addiw	s2,s2,1
    80004e34:	b755                	j	80004dd8 <pipewrite+0x80>
  int i = 0;
    80004e36:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e38:	21848513          	addi	a0,s1,536
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	30c080e7          	jalr	780(ra) # 80002148 <wakeup>
  release(&pi->lock);
    80004e44:	8526                	mv	a0,s1
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
  return i;
    80004e4e:	bfa9                	j	80004da8 <pipewrite+0x50>

0000000080004e50 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e50:	715d                	addi	sp,sp,-80
    80004e52:	e486                	sd	ra,72(sp)
    80004e54:	e0a2                	sd	s0,64(sp)
    80004e56:	fc26                	sd	s1,56(sp)
    80004e58:	f84a                	sd	s2,48(sp)
    80004e5a:	f44e                	sd	s3,40(sp)
    80004e5c:	f052                	sd	s4,32(sp)
    80004e5e:	ec56                	sd	s5,24(sp)
    80004e60:	e85a                	sd	s6,16(sp)
    80004e62:	0880                	addi	s0,sp,80
    80004e64:	84aa                	mv	s1,a0
    80004e66:	892e                	mv	s2,a1
    80004e68:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	b42080e7          	jalr	-1214(ra) # 800019ac <myproc>
    80004e72:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	d60080e7          	jalr	-672(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e7e:	2184a703          	lw	a4,536(s1)
    80004e82:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e86:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e8a:	02f71763          	bne	a4,a5,80004eb8 <piperead+0x68>
    80004e8e:	2244a783          	lw	a5,548(s1)
    80004e92:	c39d                	beqz	a5,80004eb8 <piperead+0x68>
    if(killed(pr)){
    80004e94:	8552                	mv	a0,s4
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	502080e7          	jalr	1282(ra) # 80002398 <killed>
    80004e9e:	e941                	bnez	a0,80004f2e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ea0:	85a6                	mv	a1,s1
    80004ea2:	854e                	mv	a0,s3
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	240080e7          	jalr	576(ra) # 800020e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eac:	2184a703          	lw	a4,536(s1)
    80004eb0:	21c4a783          	lw	a5,540(s1)
    80004eb4:	fcf70de3          	beq	a4,a5,80004e8e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eba:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ebc:	05505363          	blez	s5,80004f02 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004ec0:	2184a783          	lw	a5,536(s1)
    80004ec4:	21c4a703          	lw	a4,540(s1)
    80004ec8:	02f70d63          	beq	a4,a5,80004f02 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ecc:	0017871b          	addiw	a4,a5,1
    80004ed0:	20e4ac23          	sw	a4,536(s1)
    80004ed4:	1ff7f793          	andi	a5,a5,511
    80004ed8:	97a6                	add	a5,a5,s1
    80004eda:	0187c783          	lbu	a5,24(a5)
    80004ede:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ee2:	4685                	li	a3,1
    80004ee4:	fbf40613          	addi	a2,s0,-65
    80004ee8:	85ca                	mv	a1,s2
    80004eea:	058a3503          	ld	a0,88(s4)
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	77a080e7          	jalr	1914(ra) # 80001668 <copyout>
    80004ef6:	01650663          	beq	a0,s6,80004f02 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004efa:	2985                	addiw	s3,s3,1
    80004efc:	0905                	addi	s2,s2,1
    80004efe:	fd3a91e3          	bne	s5,s3,80004ec0 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f02:	21c48513          	addi	a0,s1,540
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	242080e7          	jalr	578(ra) # 80002148 <wakeup>
  release(&pi->lock);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	d7a080e7          	jalr	-646(ra) # 80000c8a <release>
  return i;
}
    80004f18:	854e                	mv	a0,s3
    80004f1a:	60a6                	ld	ra,72(sp)
    80004f1c:	6406                	ld	s0,64(sp)
    80004f1e:	74e2                	ld	s1,56(sp)
    80004f20:	7942                	ld	s2,48(sp)
    80004f22:	79a2                	ld	s3,40(sp)
    80004f24:	7a02                	ld	s4,32(sp)
    80004f26:	6ae2                	ld	s5,24(sp)
    80004f28:	6b42                	ld	s6,16(sp)
    80004f2a:	6161                	addi	sp,sp,80
    80004f2c:	8082                	ret
      release(&pi->lock);
    80004f2e:	8526                	mv	a0,s1
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d5a080e7          	jalr	-678(ra) # 80000c8a <release>
      return -1;
    80004f38:	59fd                	li	s3,-1
    80004f3a:	bff9                	j	80004f18 <piperead+0xc8>

0000000080004f3c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f3c:	1141                	addi	sp,sp,-16
    80004f3e:	e422                	sd	s0,8(sp)
    80004f40:	0800                	addi	s0,sp,16
    80004f42:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f44:	8905                	andi	a0,a0,1
    80004f46:	c111                	beqz	a0,80004f4a <flags2perm+0xe>
      perm = PTE_X;
    80004f48:	4521                	li	a0,8
    if(flags & 0x2)
    80004f4a:	8b89                	andi	a5,a5,2
    80004f4c:	c399                	beqz	a5,80004f52 <flags2perm+0x16>
      perm |= PTE_W;
    80004f4e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f52:	6422                	ld	s0,8(sp)
    80004f54:	0141                	addi	sp,sp,16
    80004f56:	8082                	ret

0000000080004f58 <exec>:

int
exec(char *path, char **argv)
{
    80004f58:	de010113          	addi	sp,sp,-544
    80004f5c:	20113c23          	sd	ra,536(sp)
    80004f60:	20813823          	sd	s0,528(sp)
    80004f64:	20913423          	sd	s1,520(sp)
    80004f68:	21213023          	sd	s2,512(sp)
    80004f6c:	ffce                	sd	s3,504(sp)
    80004f6e:	fbd2                	sd	s4,496(sp)
    80004f70:	f7d6                	sd	s5,488(sp)
    80004f72:	f3da                	sd	s6,480(sp)
    80004f74:	efde                	sd	s7,472(sp)
    80004f76:	ebe2                	sd	s8,464(sp)
    80004f78:	e7e6                	sd	s9,456(sp)
    80004f7a:	e3ea                	sd	s10,448(sp)
    80004f7c:	ff6e                	sd	s11,440(sp)
    80004f7e:	1400                	addi	s0,sp,544
    80004f80:	892a                	mv	s2,a0
    80004f82:	dea43423          	sd	a0,-536(s0)
    80004f86:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f8a:	ffffd097          	auipc	ra,0xffffd
    80004f8e:	a22080e7          	jalr	-1502(ra) # 800019ac <myproc>
    80004f92:	84aa                	mv	s1,a0

  begin_op();
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	47e080e7          	jalr	1150(ra) # 80004412 <begin_op>

  if((ip = namei(path)) == 0){
    80004f9c:	854a                	mv	a0,s2
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	258080e7          	jalr	600(ra) # 800041f6 <namei>
    80004fa6:	c93d                	beqz	a0,8000501c <exec+0xc4>
    80004fa8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	aa6080e7          	jalr	-1370(ra) # 80003a50 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fb2:	04000713          	li	a4,64
    80004fb6:	4681                	li	a3,0
    80004fb8:	e5040613          	addi	a2,s0,-432
    80004fbc:	4581                	li	a1,0
    80004fbe:	8556                	mv	a0,s5
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	d44080e7          	jalr	-700(ra) # 80003d04 <readi>
    80004fc8:	04000793          	li	a5,64
    80004fcc:	00f51a63          	bne	a0,a5,80004fe0 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fd0:	e5042703          	lw	a4,-432(s0)
    80004fd4:	464c47b7          	lui	a5,0x464c4
    80004fd8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fdc:	04f70663          	beq	a4,a5,80005028 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fe0:	8556                	mv	a0,s5
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	cd0080e7          	jalr	-816(ra) # 80003cb2 <iunlockput>
    end_op();
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	4a8080e7          	jalr	1192(ra) # 80004492 <end_op>
  }
  return -1;
    80004ff2:	557d                	li	a0,-1
}
    80004ff4:	21813083          	ld	ra,536(sp)
    80004ff8:	21013403          	ld	s0,528(sp)
    80004ffc:	20813483          	ld	s1,520(sp)
    80005000:	20013903          	ld	s2,512(sp)
    80005004:	79fe                	ld	s3,504(sp)
    80005006:	7a5e                	ld	s4,496(sp)
    80005008:	7abe                	ld	s5,488(sp)
    8000500a:	7b1e                	ld	s6,480(sp)
    8000500c:	6bfe                	ld	s7,472(sp)
    8000500e:	6c5e                	ld	s8,464(sp)
    80005010:	6cbe                	ld	s9,456(sp)
    80005012:	6d1e                	ld	s10,448(sp)
    80005014:	7dfa                	ld	s11,440(sp)
    80005016:	22010113          	addi	sp,sp,544
    8000501a:	8082                	ret
    end_op();
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	476080e7          	jalr	1142(ra) # 80004492 <end_op>
    return -1;
    80005024:	557d                	li	a0,-1
    80005026:	b7f9                	j	80004ff4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	a46080e7          	jalr	-1466(ra) # 80001a70 <proc_pagetable>
    80005032:	8b2a                	mv	s6,a0
    80005034:	d555                	beqz	a0,80004fe0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005036:	e7042783          	lw	a5,-400(s0)
    8000503a:	e8845703          	lhu	a4,-376(s0)
    8000503e:	c735                	beqz	a4,800050aa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005040:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005042:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005046:	6a05                	lui	s4,0x1
    80005048:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000504c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005050:	6d85                	lui	s11,0x1
    80005052:	7d7d                	lui	s10,0xfffff
    80005054:	a481                	j	80005294 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005056:	00003517          	auipc	a0,0x3
    8000505a:	69a50513          	addi	a0,a0,1690 # 800086f0 <syscalls+0x2a0>
    8000505e:	ffffb097          	auipc	ra,0xffffb
    80005062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005066:	874a                	mv	a4,s2
    80005068:	009c86bb          	addw	a3,s9,s1
    8000506c:	4581                	li	a1,0
    8000506e:	8556                	mv	a0,s5
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	c94080e7          	jalr	-876(ra) # 80003d04 <readi>
    80005078:	2501                	sext.w	a0,a0
    8000507a:	1aa91a63          	bne	s2,a0,8000522e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000507e:	009d84bb          	addw	s1,s11,s1
    80005082:	013d09bb          	addw	s3,s10,s3
    80005086:	1f74f763          	bgeu	s1,s7,80005274 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000508a:	02049593          	slli	a1,s1,0x20
    8000508e:	9181                	srli	a1,a1,0x20
    80005090:	95e2                	add	a1,a1,s8
    80005092:	855a                	mv	a0,s6
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	fc8080e7          	jalr	-56(ra) # 8000105c <walkaddr>
    8000509c:	862a                	mv	a2,a0
    if(pa == 0)
    8000509e:	dd45                	beqz	a0,80005056 <exec+0xfe>
      n = PGSIZE;
    800050a0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050a2:	fd49f2e3          	bgeu	s3,s4,80005066 <exec+0x10e>
      n = sz - i;
    800050a6:	894e                	mv	s2,s3
    800050a8:	bf7d                	j	80005066 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050aa:	4901                	li	s2,0
  iunlockput(ip);
    800050ac:	8556                	mv	a0,s5
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	c04080e7          	jalr	-1020(ra) # 80003cb2 <iunlockput>
  end_op();
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	3dc080e7          	jalr	988(ra) # 80004492 <end_op>
  p = myproc();
    800050be:	ffffd097          	auipc	ra,0xffffd
    800050c2:	8ee080e7          	jalr	-1810(ra) # 800019ac <myproc>
    800050c6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050c8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050cc:	6785                	lui	a5,0x1
    800050ce:	17fd                	addi	a5,a5,-1
    800050d0:	993e                	add	s2,s2,a5
    800050d2:	77fd                	lui	a5,0xfffff
    800050d4:	00f977b3          	and	a5,s2,a5
    800050d8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050dc:	4691                	li	a3,4
    800050de:	6609                	lui	a2,0x2
    800050e0:	963e                	add	a2,a2,a5
    800050e2:	85be                	mv	a1,a5
    800050e4:	855a                	mv	a0,s6
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	32a080e7          	jalr	810(ra) # 80001410 <uvmalloc>
    800050ee:	8c2a                	mv	s8,a0
  ip = 0;
    800050f0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050f2:	12050e63          	beqz	a0,8000522e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050f6:	75f9                	lui	a1,0xffffe
    800050f8:	95aa                	add	a1,a1,a0
    800050fa:	855a                	mv	a0,s6
    800050fc:	ffffc097          	auipc	ra,0xffffc
    80005100:	53a080e7          	jalr	1338(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80005104:	7afd                	lui	s5,0xfffff
    80005106:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005108:	df043783          	ld	a5,-528(s0)
    8000510c:	6388                	ld	a0,0(a5)
    8000510e:	c925                	beqz	a0,8000517e <exec+0x226>
    80005110:	e9040993          	addi	s3,s0,-368
    80005114:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005118:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000511a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	d32080e7          	jalr	-718(ra) # 80000e4e <strlen>
    80005124:	0015079b          	addiw	a5,a0,1
    80005128:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000512c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005130:	13596663          	bltu	s2,s5,8000525c <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005134:	df043d83          	ld	s11,-528(s0)
    80005138:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000513c:	8552                	mv	a0,s4
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	d10080e7          	jalr	-752(ra) # 80000e4e <strlen>
    80005146:	0015069b          	addiw	a3,a0,1
    8000514a:	8652                	mv	a2,s4
    8000514c:	85ca                	mv	a1,s2
    8000514e:	855a                	mv	a0,s6
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	518080e7          	jalr	1304(ra) # 80001668 <copyout>
    80005158:	10054663          	bltz	a0,80005264 <exec+0x30c>
    ustack[argc] = sp;
    8000515c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005160:	0485                	addi	s1,s1,1
    80005162:	008d8793          	addi	a5,s11,8
    80005166:	def43823          	sd	a5,-528(s0)
    8000516a:	008db503          	ld	a0,8(s11)
    8000516e:	c911                	beqz	a0,80005182 <exec+0x22a>
    if(argc >= MAXARG)
    80005170:	09a1                	addi	s3,s3,8
    80005172:	fb3c95e3          	bne	s9,s3,8000511c <exec+0x1c4>
  sz = sz1;
    80005176:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000517a:	4a81                	li	s5,0
    8000517c:	a84d                	j	8000522e <exec+0x2d6>
  sp = sz;
    8000517e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005180:	4481                	li	s1,0
  ustack[argc] = 0;
    80005182:	00349793          	slli	a5,s1,0x3
    80005186:	f9040713          	addi	a4,s0,-112
    8000518a:	97ba                	add	a5,a5,a4
    8000518c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc5a0>
  sp -= (argc+1) * sizeof(uint64);
    80005190:	00148693          	addi	a3,s1,1
    80005194:	068e                	slli	a3,a3,0x3
    80005196:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000519a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000519e:	01597663          	bgeu	s2,s5,800051aa <exec+0x252>
  sz = sz1;
    800051a2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a6:	4a81                	li	s5,0
    800051a8:	a059                	j	8000522e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051aa:	e9040613          	addi	a2,s0,-368
    800051ae:	85ca                	mv	a1,s2
    800051b0:	855a                	mv	a0,s6
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	4b6080e7          	jalr	1206(ra) # 80001668 <copyout>
    800051ba:	0a054963          	bltz	a0,8000526c <exec+0x314>
  p->trapframe->a1 = sp;
    800051be:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    800051c2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051c6:	de843783          	ld	a5,-536(s0)
    800051ca:	0007c703          	lbu	a4,0(a5)
    800051ce:	cf11                	beqz	a4,800051ea <exec+0x292>
    800051d0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051d2:	02f00693          	li	a3,47
    800051d6:	a039                	j	800051e4 <exec+0x28c>
      last = s+1;
    800051d8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051dc:	0785                	addi	a5,a5,1
    800051de:	fff7c703          	lbu	a4,-1(a5)
    800051e2:	c701                	beqz	a4,800051ea <exec+0x292>
    if(*s == '/')
    800051e4:	fed71ce3          	bne	a4,a3,800051dc <exec+0x284>
    800051e8:	bfc5                	j	800051d8 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800051ea:	4641                	li	a2,16
    800051ec:	de843583          	ld	a1,-536(s0)
    800051f0:	178b8513          	addi	a0,s7,376
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	c28080e7          	jalr	-984(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051fc:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005200:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005204:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005208:	060bb783          	ld	a5,96(s7)
    8000520c:	e6843703          	ld	a4,-408(s0)
    80005210:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005212:	060bb783          	ld	a5,96(s7)
    80005216:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000521a:	85ea                	mv	a1,s10
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	8f0080e7          	jalr	-1808(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005224:	0004851b          	sext.w	a0,s1
    80005228:	b3f1                	j	80004ff4 <exec+0x9c>
    8000522a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000522e:	df843583          	ld	a1,-520(s0)
    80005232:	855a                	mv	a0,s6
    80005234:	ffffd097          	auipc	ra,0xffffd
    80005238:	8d8080e7          	jalr	-1832(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000523c:	da0a92e3          	bnez	s5,80004fe0 <exec+0x88>
  return -1;
    80005240:	557d                	li	a0,-1
    80005242:	bb4d                	j	80004ff4 <exec+0x9c>
    80005244:	df243c23          	sd	s2,-520(s0)
    80005248:	b7dd                	j	8000522e <exec+0x2d6>
    8000524a:	df243c23          	sd	s2,-520(s0)
    8000524e:	b7c5                	j	8000522e <exec+0x2d6>
    80005250:	df243c23          	sd	s2,-520(s0)
    80005254:	bfe9                	j	8000522e <exec+0x2d6>
    80005256:	df243c23          	sd	s2,-520(s0)
    8000525a:	bfd1                	j	8000522e <exec+0x2d6>
  sz = sz1;
    8000525c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005260:	4a81                	li	s5,0
    80005262:	b7f1                	j	8000522e <exec+0x2d6>
  sz = sz1;
    80005264:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005268:	4a81                	li	s5,0
    8000526a:	b7d1                	j	8000522e <exec+0x2d6>
  sz = sz1;
    8000526c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005270:	4a81                	li	s5,0
    80005272:	bf75                	j	8000522e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005274:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005278:	e0843783          	ld	a5,-504(s0)
    8000527c:	0017869b          	addiw	a3,a5,1
    80005280:	e0d43423          	sd	a3,-504(s0)
    80005284:	e0043783          	ld	a5,-512(s0)
    80005288:	0387879b          	addiw	a5,a5,56
    8000528c:	e8845703          	lhu	a4,-376(s0)
    80005290:	e0e6dee3          	bge	a3,a4,800050ac <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005294:	2781                	sext.w	a5,a5
    80005296:	e0f43023          	sd	a5,-512(s0)
    8000529a:	03800713          	li	a4,56
    8000529e:	86be                	mv	a3,a5
    800052a0:	e1840613          	addi	a2,s0,-488
    800052a4:	4581                	li	a1,0
    800052a6:	8556                	mv	a0,s5
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	a5c080e7          	jalr	-1444(ra) # 80003d04 <readi>
    800052b0:	03800793          	li	a5,56
    800052b4:	f6f51be3          	bne	a0,a5,8000522a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800052b8:	e1842783          	lw	a5,-488(s0)
    800052bc:	4705                	li	a4,1
    800052be:	fae79de3          	bne	a5,a4,80005278 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800052c2:	e4043483          	ld	s1,-448(s0)
    800052c6:	e3843783          	ld	a5,-456(s0)
    800052ca:	f6f4ede3          	bltu	s1,a5,80005244 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052ce:	e2843783          	ld	a5,-472(s0)
    800052d2:	94be                	add	s1,s1,a5
    800052d4:	f6f4ebe3          	bltu	s1,a5,8000524a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800052d8:	de043703          	ld	a4,-544(s0)
    800052dc:	8ff9                	and	a5,a5,a4
    800052de:	fbad                	bnez	a5,80005250 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e0:	e1c42503          	lw	a0,-484(s0)
    800052e4:	00000097          	auipc	ra,0x0
    800052e8:	c58080e7          	jalr	-936(ra) # 80004f3c <flags2perm>
    800052ec:	86aa                	mv	a3,a0
    800052ee:	8626                	mv	a2,s1
    800052f0:	85ca                	mv	a1,s2
    800052f2:	855a                	mv	a0,s6
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	11c080e7          	jalr	284(ra) # 80001410 <uvmalloc>
    800052fc:	dea43c23          	sd	a0,-520(s0)
    80005300:	d939                	beqz	a0,80005256 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005302:	e2843c03          	ld	s8,-472(s0)
    80005306:	e2042c83          	lw	s9,-480(s0)
    8000530a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000530e:	f60b83e3          	beqz	s7,80005274 <exec+0x31c>
    80005312:	89de                	mv	s3,s7
    80005314:	4481                	li	s1,0
    80005316:	bb95                	j	8000508a <exec+0x132>

0000000080005318 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005318:	7179                	addi	sp,sp,-48
    8000531a:	f406                	sd	ra,40(sp)
    8000531c:	f022                	sd	s0,32(sp)
    8000531e:	ec26                	sd	s1,24(sp)
    80005320:	e84a                	sd	s2,16(sp)
    80005322:	1800                	addi	s0,sp,48
    80005324:	892e                	mv	s2,a1
    80005326:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005328:	fdc40593          	addi	a1,s0,-36
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	a68080e7          	jalr	-1432(ra) # 80002d94 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005334:	fdc42703          	lw	a4,-36(s0)
    80005338:	47bd                	li	a5,15
    8000533a:	02e7eb63          	bltu	a5,a4,80005370 <argfd+0x58>
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	66e080e7          	jalr	1646(ra) # 800019ac <myproc>
    80005346:	fdc42703          	lw	a4,-36(s0)
    8000534a:	01e70793          	addi	a5,a4,30
    8000534e:	078e                	slli	a5,a5,0x3
    80005350:	953e                	add	a0,a0,a5
    80005352:	611c                	ld	a5,0(a0)
    80005354:	c385                	beqz	a5,80005374 <argfd+0x5c>
    return -1;
  if(pfd)
    80005356:	00090463          	beqz	s2,8000535e <argfd+0x46>
    *pfd = fd;
    8000535a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000535e:	4501                	li	a0,0
  if(pf)
    80005360:	c091                	beqz	s1,80005364 <argfd+0x4c>
    *pf = f;
    80005362:	e09c                	sd	a5,0(s1)
}
    80005364:	70a2                	ld	ra,40(sp)
    80005366:	7402                	ld	s0,32(sp)
    80005368:	64e2                	ld	s1,24(sp)
    8000536a:	6942                	ld	s2,16(sp)
    8000536c:	6145                	addi	sp,sp,48
    8000536e:	8082                	ret
    return -1;
    80005370:	557d                	li	a0,-1
    80005372:	bfcd                	j	80005364 <argfd+0x4c>
    80005374:	557d                	li	a0,-1
    80005376:	b7fd                	j	80005364 <argfd+0x4c>

0000000080005378 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005378:	1101                	addi	sp,sp,-32
    8000537a:	ec06                	sd	ra,24(sp)
    8000537c:	e822                	sd	s0,16(sp)
    8000537e:	e426                	sd	s1,8(sp)
    80005380:	1000                	addi	s0,sp,32
    80005382:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005384:	ffffc097          	auipc	ra,0xffffc
    80005388:	628080e7          	jalr	1576(ra) # 800019ac <myproc>
    8000538c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000538e:	0f050793          	addi	a5,a0,240
    80005392:	4501                	li	a0,0
    80005394:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005396:	6398                	ld	a4,0(a5)
    80005398:	cb19                	beqz	a4,800053ae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000539a:	2505                	addiw	a0,a0,1
    8000539c:	07a1                	addi	a5,a5,8
    8000539e:	fed51ce3          	bne	a0,a3,80005396 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053a2:	557d                	li	a0,-1
}
    800053a4:	60e2                	ld	ra,24(sp)
    800053a6:	6442                	ld	s0,16(sp)
    800053a8:	64a2                	ld	s1,8(sp)
    800053aa:	6105                	addi	sp,sp,32
    800053ac:	8082                	ret
      p->ofile[fd] = f;
    800053ae:	01e50793          	addi	a5,a0,30
    800053b2:	078e                	slli	a5,a5,0x3
    800053b4:	963e                	add	a2,a2,a5
    800053b6:	e204                	sd	s1,0(a2)
      return fd;
    800053b8:	b7f5                	j	800053a4 <fdalloc+0x2c>

00000000800053ba <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053ba:	715d                	addi	sp,sp,-80
    800053bc:	e486                	sd	ra,72(sp)
    800053be:	e0a2                	sd	s0,64(sp)
    800053c0:	fc26                	sd	s1,56(sp)
    800053c2:	f84a                	sd	s2,48(sp)
    800053c4:	f44e                	sd	s3,40(sp)
    800053c6:	f052                	sd	s4,32(sp)
    800053c8:	ec56                	sd	s5,24(sp)
    800053ca:	e85a                	sd	s6,16(sp)
    800053cc:	0880                	addi	s0,sp,80
    800053ce:	8b2e                	mv	s6,a1
    800053d0:	89b2                	mv	s3,a2
    800053d2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053d4:	fb040593          	addi	a1,s0,-80
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	e3c080e7          	jalr	-452(ra) # 80004214 <nameiparent>
    800053e0:	84aa                	mv	s1,a0
    800053e2:	14050f63          	beqz	a0,80005540 <create+0x186>
    return 0;

  ilock(dp);
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	66a080e7          	jalr	1642(ra) # 80003a50 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053ee:	4601                	li	a2,0
    800053f0:	fb040593          	addi	a1,s0,-80
    800053f4:	8526                	mv	a0,s1
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	b3e080e7          	jalr	-1218(ra) # 80003f34 <dirlookup>
    800053fe:	8aaa                	mv	s5,a0
    80005400:	c931                	beqz	a0,80005454 <create+0x9a>
    iunlockput(dp);
    80005402:	8526                	mv	a0,s1
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	8ae080e7          	jalr	-1874(ra) # 80003cb2 <iunlockput>
    ilock(ip);
    8000540c:	8556                	mv	a0,s5
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	642080e7          	jalr	1602(ra) # 80003a50 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005416:	000b059b          	sext.w	a1,s6
    8000541a:	4789                	li	a5,2
    8000541c:	02f59563          	bne	a1,a5,80005446 <create+0x8c>
    80005420:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6e4>
    80005424:	37f9                	addiw	a5,a5,-2
    80005426:	17c2                	slli	a5,a5,0x30
    80005428:	93c1                	srli	a5,a5,0x30
    8000542a:	4705                	li	a4,1
    8000542c:	00f76d63          	bltu	a4,a5,80005446 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005430:	8556                	mv	a0,s5
    80005432:	60a6                	ld	ra,72(sp)
    80005434:	6406                	ld	s0,64(sp)
    80005436:	74e2                	ld	s1,56(sp)
    80005438:	7942                	ld	s2,48(sp)
    8000543a:	79a2                	ld	s3,40(sp)
    8000543c:	7a02                	ld	s4,32(sp)
    8000543e:	6ae2                	ld	s5,24(sp)
    80005440:	6b42                	ld	s6,16(sp)
    80005442:	6161                	addi	sp,sp,80
    80005444:	8082                	ret
    iunlockput(ip);
    80005446:	8556                	mv	a0,s5
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	86a080e7          	jalr	-1942(ra) # 80003cb2 <iunlockput>
    return 0;
    80005450:	4a81                	li	s5,0
    80005452:	bff9                	j	80005430 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005454:	85da                	mv	a1,s6
    80005456:	4088                	lw	a0,0(s1)
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	45c080e7          	jalr	1116(ra) # 800038b4 <ialloc>
    80005460:	8a2a                	mv	s4,a0
    80005462:	c539                	beqz	a0,800054b0 <create+0xf6>
  ilock(ip);
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	5ec080e7          	jalr	1516(ra) # 80003a50 <ilock>
  ip->major = major;
    8000546c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005470:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005474:	4905                	li	s2,1
    80005476:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000547a:	8552                	mv	a0,s4
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	50a080e7          	jalr	1290(ra) # 80003986 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005484:	000b059b          	sext.w	a1,s6
    80005488:	03258b63          	beq	a1,s2,800054be <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000548c:	004a2603          	lw	a2,4(s4)
    80005490:	fb040593          	addi	a1,s0,-80
    80005494:	8526                	mv	a0,s1
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	cae080e7          	jalr	-850(ra) # 80004144 <dirlink>
    8000549e:	06054f63          	bltz	a0,8000551c <create+0x162>
  iunlockput(dp);
    800054a2:	8526                	mv	a0,s1
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	80e080e7          	jalr	-2034(ra) # 80003cb2 <iunlockput>
  return ip;
    800054ac:	8ad2                	mv	s5,s4
    800054ae:	b749                	j	80005430 <create+0x76>
    iunlockput(dp);
    800054b0:	8526                	mv	a0,s1
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	800080e7          	jalr	-2048(ra) # 80003cb2 <iunlockput>
    return 0;
    800054ba:	8ad2                	mv	s5,s4
    800054bc:	bf95                	j	80005430 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054be:	004a2603          	lw	a2,4(s4)
    800054c2:	00003597          	auipc	a1,0x3
    800054c6:	24e58593          	addi	a1,a1,590 # 80008710 <syscalls+0x2c0>
    800054ca:	8552                	mv	a0,s4
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	c78080e7          	jalr	-904(ra) # 80004144 <dirlink>
    800054d4:	04054463          	bltz	a0,8000551c <create+0x162>
    800054d8:	40d0                	lw	a2,4(s1)
    800054da:	00003597          	auipc	a1,0x3
    800054de:	23e58593          	addi	a1,a1,574 # 80008718 <syscalls+0x2c8>
    800054e2:	8552                	mv	a0,s4
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	c60080e7          	jalr	-928(ra) # 80004144 <dirlink>
    800054ec:	02054863          	bltz	a0,8000551c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054f0:	004a2603          	lw	a2,4(s4)
    800054f4:	fb040593          	addi	a1,s0,-80
    800054f8:	8526                	mv	a0,s1
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	c4a080e7          	jalr	-950(ra) # 80004144 <dirlink>
    80005502:	00054d63          	bltz	a0,8000551c <create+0x162>
    dp->nlink++;  // for ".."
    80005506:	04a4d783          	lhu	a5,74(s1)
    8000550a:	2785                	addiw	a5,a5,1
    8000550c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	474080e7          	jalr	1140(ra) # 80003986 <iupdate>
    8000551a:	b761                	j	800054a2 <create+0xe8>
  ip->nlink = 0;
    8000551c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005520:	8552                	mv	a0,s4
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	464080e7          	jalr	1124(ra) # 80003986 <iupdate>
  iunlockput(ip);
    8000552a:	8552                	mv	a0,s4
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	786080e7          	jalr	1926(ra) # 80003cb2 <iunlockput>
  iunlockput(dp);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	77c080e7          	jalr	1916(ra) # 80003cb2 <iunlockput>
  return 0;
    8000553e:	bdcd                	j	80005430 <create+0x76>
    return 0;
    80005540:	8aaa                	mv	s5,a0
    80005542:	b5fd                	j	80005430 <create+0x76>

0000000080005544 <sys_dup>:
{
    80005544:	7179                	addi	sp,sp,-48
    80005546:	f406                	sd	ra,40(sp)
    80005548:	f022                	sd	s0,32(sp)
    8000554a:	ec26                	sd	s1,24(sp)
    8000554c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000554e:	fd840613          	addi	a2,s0,-40
    80005552:	4581                	li	a1,0
    80005554:	4501                	li	a0,0
    80005556:	00000097          	auipc	ra,0x0
    8000555a:	dc2080e7          	jalr	-574(ra) # 80005318 <argfd>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005560:	02054363          	bltz	a0,80005586 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005564:	fd843503          	ld	a0,-40(s0)
    80005568:	00000097          	auipc	ra,0x0
    8000556c:	e10080e7          	jalr	-496(ra) # 80005378 <fdalloc>
    80005570:	84aa                	mv	s1,a0
    return -1;
    80005572:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005574:	00054963          	bltz	a0,80005586 <sys_dup+0x42>
  filedup(f);
    80005578:	fd843503          	ld	a0,-40(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	310080e7          	jalr	784(ra) # 8000488c <filedup>
  return fd;
    80005584:	87a6                	mv	a5,s1
}
    80005586:	853e                	mv	a0,a5
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	64e2                	ld	s1,24(sp)
    8000558e:	6145                	addi	sp,sp,48
    80005590:	8082                	ret

0000000080005592 <sys_read>:
{
    80005592:	7179                	addi	sp,sp,-48
    80005594:	f406                	sd	ra,40(sp)
    80005596:	f022                	sd	s0,32(sp)
    80005598:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000559a:	fd840593          	addi	a1,s0,-40
    8000559e:	4505                	li	a0,1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	814080e7          	jalr	-2028(ra) # 80002db4 <argaddr>
  argint(2, &n);
    800055a8:	fe440593          	addi	a1,s0,-28
    800055ac:	4509                	li	a0,2
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	7e6080e7          	jalr	2022(ra) # 80002d94 <argint>
  if(argfd(0, 0, &f) < 0)
    800055b6:	fe840613          	addi	a2,s0,-24
    800055ba:	4581                	li	a1,0
    800055bc:	4501                	li	a0,0
    800055be:	00000097          	auipc	ra,0x0
    800055c2:	d5a080e7          	jalr	-678(ra) # 80005318 <argfd>
    800055c6:	87aa                	mv	a5,a0
    return -1;
    800055c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ca:	0007cc63          	bltz	a5,800055e2 <sys_read+0x50>
  return fileread(f, p, n);
    800055ce:	fe442603          	lw	a2,-28(s0)
    800055d2:	fd843583          	ld	a1,-40(s0)
    800055d6:	fe843503          	ld	a0,-24(s0)
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	43e080e7          	jalr	1086(ra) # 80004a18 <fileread>
}
    800055e2:	70a2                	ld	ra,40(sp)
    800055e4:	7402                	ld	s0,32(sp)
    800055e6:	6145                	addi	sp,sp,48
    800055e8:	8082                	ret

00000000800055ea <sys_write>:
{
    800055ea:	7179                	addi	sp,sp,-48
    800055ec:	f406                	sd	ra,40(sp)
    800055ee:	f022                	sd	s0,32(sp)
    800055f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055f2:	fd840593          	addi	a1,s0,-40
    800055f6:	4505                	li	a0,1
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	7bc080e7          	jalr	1980(ra) # 80002db4 <argaddr>
  argint(2, &n);
    80005600:	fe440593          	addi	a1,s0,-28
    80005604:	4509                	li	a0,2
    80005606:	ffffd097          	auipc	ra,0xffffd
    8000560a:	78e080e7          	jalr	1934(ra) # 80002d94 <argint>
  if(argfd(0, 0, &f) < 0)
    8000560e:	fe840613          	addi	a2,s0,-24
    80005612:	4581                	li	a1,0
    80005614:	4501                	li	a0,0
    80005616:	00000097          	auipc	ra,0x0
    8000561a:	d02080e7          	jalr	-766(ra) # 80005318 <argfd>
    8000561e:	87aa                	mv	a5,a0
    return -1;
    80005620:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005622:	0007cc63          	bltz	a5,8000563a <sys_write+0x50>
  return filewrite(f, p, n);
    80005626:	fe442603          	lw	a2,-28(s0)
    8000562a:	fd843583          	ld	a1,-40(s0)
    8000562e:	fe843503          	ld	a0,-24(s0)
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	4a8080e7          	jalr	1192(ra) # 80004ada <filewrite>
}
    8000563a:	70a2                	ld	ra,40(sp)
    8000563c:	7402                	ld	s0,32(sp)
    8000563e:	6145                	addi	sp,sp,48
    80005640:	8082                	ret

0000000080005642 <sys_close>:
{
    80005642:	1101                	addi	sp,sp,-32
    80005644:	ec06                	sd	ra,24(sp)
    80005646:	e822                	sd	s0,16(sp)
    80005648:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000564a:	fe040613          	addi	a2,s0,-32
    8000564e:	fec40593          	addi	a1,s0,-20
    80005652:	4501                	li	a0,0
    80005654:	00000097          	auipc	ra,0x0
    80005658:	cc4080e7          	jalr	-828(ra) # 80005318 <argfd>
    return -1;
    8000565c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000565e:	02054463          	bltz	a0,80005686 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005662:	ffffc097          	auipc	ra,0xffffc
    80005666:	34a080e7          	jalr	842(ra) # 800019ac <myproc>
    8000566a:	fec42783          	lw	a5,-20(s0)
    8000566e:	07f9                	addi	a5,a5,30
    80005670:	078e                	slli	a5,a5,0x3
    80005672:	97aa                	add	a5,a5,a0
    80005674:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005678:	fe043503          	ld	a0,-32(s0)
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	262080e7          	jalr	610(ra) # 800048de <fileclose>
  return 0;
    80005684:	4781                	li	a5,0
}
    80005686:	853e                	mv	a0,a5
    80005688:	60e2                	ld	ra,24(sp)
    8000568a:	6442                	ld	s0,16(sp)
    8000568c:	6105                	addi	sp,sp,32
    8000568e:	8082                	ret

0000000080005690 <sys_fstat>:
{
    80005690:	1101                	addi	sp,sp,-32
    80005692:	ec06                	sd	ra,24(sp)
    80005694:	e822                	sd	s0,16(sp)
    80005696:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005698:	fe040593          	addi	a1,s0,-32
    8000569c:	4505                	li	a0,1
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	716080e7          	jalr	1814(ra) # 80002db4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800056a6:	fe840613          	addi	a2,s0,-24
    800056aa:	4581                	li	a1,0
    800056ac:	4501                	li	a0,0
    800056ae:	00000097          	auipc	ra,0x0
    800056b2:	c6a080e7          	jalr	-918(ra) # 80005318 <argfd>
    800056b6:	87aa                	mv	a5,a0
    return -1;
    800056b8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056ba:	0007ca63          	bltz	a5,800056ce <sys_fstat+0x3e>
  return filestat(f, st);
    800056be:	fe043583          	ld	a1,-32(s0)
    800056c2:	fe843503          	ld	a0,-24(s0)
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	2e0080e7          	jalr	736(ra) # 800049a6 <filestat>
}
    800056ce:	60e2                	ld	ra,24(sp)
    800056d0:	6442                	ld	s0,16(sp)
    800056d2:	6105                	addi	sp,sp,32
    800056d4:	8082                	ret

00000000800056d6 <sys_link>:
{
    800056d6:	7169                	addi	sp,sp,-304
    800056d8:	f606                	sd	ra,296(sp)
    800056da:	f222                	sd	s0,288(sp)
    800056dc:	ee26                	sd	s1,280(sp)
    800056de:	ea4a                	sd	s2,272(sp)
    800056e0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056e2:	08000613          	li	a2,128
    800056e6:	ed040593          	addi	a1,s0,-304
    800056ea:	4501                	li	a0,0
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	736080e7          	jalr	1846(ra) # 80002e22 <argstr>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056f6:	10054e63          	bltz	a0,80005812 <sys_link+0x13c>
    800056fa:	08000613          	li	a2,128
    800056fe:	f5040593          	addi	a1,s0,-176
    80005702:	4505                	li	a0,1
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	71e080e7          	jalr	1822(ra) # 80002e22 <argstr>
    return -1;
    8000570c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000570e:	10054263          	bltz	a0,80005812 <sys_link+0x13c>
  begin_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	d00080e7          	jalr	-768(ra) # 80004412 <begin_op>
  if((ip = namei(old)) == 0){
    8000571a:	ed040513          	addi	a0,s0,-304
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	ad8080e7          	jalr	-1320(ra) # 800041f6 <namei>
    80005726:	84aa                	mv	s1,a0
    80005728:	c551                	beqz	a0,800057b4 <sys_link+0xde>
  ilock(ip);
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	326080e7          	jalr	806(ra) # 80003a50 <ilock>
  if(ip->type == T_DIR){
    80005732:	04449703          	lh	a4,68(s1)
    80005736:	4785                	li	a5,1
    80005738:	08f70463          	beq	a4,a5,800057c0 <sys_link+0xea>
  ip->nlink++;
    8000573c:	04a4d783          	lhu	a5,74(s1)
    80005740:	2785                	addiw	a5,a5,1
    80005742:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	23e080e7          	jalr	574(ra) # 80003986 <iupdate>
  iunlock(ip);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	3c0080e7          	jalr	960(ra) # 80003b12 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000575a:	fd040593          	addi	a1,s0,-48
    8000575e:	f5040513          	addi	a0,s0,-176
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	ab2080e7          	jalr	-1358(ra) # 80004214 <nameiparent>
    8000576a:	892a                	mv	s2,a0
    8000576c:	c935                	beqz	a0,800057e0 <sys_link+0x10a>
  ilock(dp);
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	2e2080e7          	jalr	738(ra) # 80003a50 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005776:	00092703          	lw	a4,0(s2)
    8000577a:	409c                	lw	a5,0(s1)
    8000577c:	04f71d63          	bne	a4,a5,800057d6 <sys_link+0x100>
    80005780:	40d0                	lw	a2,4(s1)
    80005782:	fd040593          	addi	a1,s0,-48
    80005786:	854a                	mv	a0,s2
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	9bc080e7          	jalr	-1604(ra) # 80004144 <dirlink>
    80005790:	04054363          	bltz	a0,800057d6 <sys_link+0x100>
  iunlockput(dp);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	51c080e7          	jalr	1308(ra) # 80003cb2 <iunlockput>
  iput(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	46a080e7          	jalr	1130(ra) # 80003c0a <iput>
  end_op();
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	cea080e7          	jalr	-790(ra) # 80004492 <end_op>
  return 0;
    800057b0:	4781                	li	a5,0
    800057b2:	a085                	j	80005812 <sys_link+0x13c>
    end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	cde080e7          	jalr	-802(ra) # 80004492 <end_op>
    return -1;
    800057bc:	57fd                	li	a5,-1
    800057be:	a891                	j	80005812 <sys_link+0x13c>
    iunlockput(ip);
    800057c0:	8526                	mv	a0,s1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	4f0080e7          	jalr	1264(ra) # 80003cb2 <iunlockput>
    end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	cc8080e7          	jalr	-824(ra) # 80004492 <end_op>
    return -1;
    800057d2:	57fd                	li	a5,-1
    800057d4:	a83d                	j	80005812 <sys_link+0x13c>
    iunlockput(dp);
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	4da080e7          	jalr	1242(ra) # 80003cb2 <iunlockput>
  ilock(ip);
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	26e080e7          	jalr	622(ra) # 80003a50 <ilock>
  ip->nlink--;
    800057ea:	04a4d783          	lhu	a5,74(s1)
    800057ee:	37fd                	addiw	a5,a5,-1
    800057f0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	190080e7          	jalr	400(ra) # 80003986 <iupdate>
  iunlockput(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	4b2080e7          	jalr	1202(ra) # 80003cb2 <iunlockput>
  end_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	c8a080e7          	jalr	-886(ra) # 80004492 <end_op>
  return -1;
    80005810:	57fd                	li	a5,-1
}
    80005812:	853e                	mv	a0,a5
    80005814:	70b2                	ld	ra,296(sp)
    80005816:	7412                	ld	s0,288(sp)
    80005818:	64f2                	ld	s1,280(sp)
    8000581a:	6952                	ld	s2,272(sp)
    8000581c:	6155                	addi	sp,sp,304
    8000581e:	8082                	ret

0000000080005820 <sys_unlink>:
{
    80005820:	7151                	addi	sp,sp,-240
    80005822:	f586                	sd	ra,232(sp)
    80005824:	f1a2                	sd	s0,224(sp)
    80005826:	eda6                	sd	s1,216(sp)
    80005828:	e9ca                	sd	s2,208(sp)
    8000582a:	e5ce                	sd	s3,200(sp)
    8000582c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000582e:	08000613          	li	a2,128
    80005832:	f3040593          	addi	a1,s0,-208
    80005836:	4501                	li	a0,0
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	5ea080e7          	jalr	1514(ra) # 80002e22 <argstr>
    80005840:	18054163          	bltz	a0,800059c2 <sys_unlink+0x1a2>
  begin_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	bce080e7          	jalr	-1074(ra) # 80004412 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000584c:	fb040593          	addi	a1,s0,-80
    80005850:	f3040513          	addi	a0,s0,-208
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	9c0080e7          	jalr	-1600(ra) # 80004214 <nameiparent>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	c979                	beqz	a0,80005934 <sys_unlink+0x114>
  ilock(dp);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	1f0080e7          	jalr	496(ra) # 80003a50 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005868:	00003597          	auipc	a1,0x3
    8000586c:	ea858593          	addi	a1,a1,-344 # 80008710 <syscalls+0x2c0>
    80005870:	fb040513          	addi	a0,s0,-80
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	6a6080e7          	jalr	1702(ra) # 80003f1a <namecmp>
    8000587c:	14050a63          	beqz	a0,800059d0 <sys_unlink+0x1b0>
    80005880:	00003597          	auipc	a1,0x3
    80005884:	e9858593          	addi	a1,a1,-360 # 80008718 <syscalls+0x2c8>
    80005888:	fb040513          	addi	a0,s0,-80
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	68e080e7          	jalr	1678(ra) # 80003f1a <namecmp>
    80005894:	12050e63          	beqz	a0,800059d0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005898:	f2c40613          	addi	a2,s0,-212
    8000589c:	fb040593          	addi	a1,s0,-80
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	692080e7          	jalr	1682(ra) # 80003f34 <dirlookup>
    800058aa:	892a                	mv	s2,a0
    800058ac:	12050263          	beqz	a0,800059d0 <sys_unlink+0x1b0>
  ilock(ip);
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	1a0080e7          	jalr	416(ra) # 80003a50 <ilock>
  if(ip->nlink < 1)
    800058b8:	04a91783          	lh	a5,74(s2)
    800058bc:	08f05263          	blez	a5,80005940 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058c0:	04491703          	lh	a4,68(s2)
    800058c4:	4785                	li	a5,1
    800058c6:	08f70563          	beq	a4,a5,80005950 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058ca:	4641                	li	a2,16
    800058cc:	4581                	li	a1,0
    800058ce:	fc040513          	addi	a0,s0,-64
    800058d2:	ffffb097          	auipc	ra,0xffffb
    800058d6:	400080e7          	jalr	1024(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058da:	4741                	li	a4,16
    800058dc:	f2c42683          	lw	a3,-212(s0)
    800058e0:	fc040613          	addi	a2,s0,-64
    800058e4:	4581                	li	a1,0
    800058e6:	8526                	mv	a0,s1
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	514080e7          	jalr	1300(ra) # 80003dfc <writei>
    800058f0:	47c1                	li	a5,16
    800058f2:	0af51563          	bne	a0,a5,8000599c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058f6:	04491703          	lh	a4,68(s2)
    800058fa:	4785                	li	a5,1
    800058fc:	0af70863          	beq	a4,a5,800059ac <sys_unlink+0x18c>
  iunlockput(dp);
    80005900:	8526                	mv	a0,s1
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	3b0080e7          	jalr	944(ra) # 80003cb2 <iunlockput>
  ip->nlink--;
    8000590a:	04a95783          	lhu	a5,74(s2)
    8000590e:	37fd                	addiw	a5,a5,-1
    80005910:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005914:	854a                	mv	a0,s2
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	070080e7          	jalr	112(ra) # 80003986 <iupdate>
  iunlockput(ip);
    8000591e:	854a                	mv	a0,s2
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	392080e7          	jalr	914(ra) # 80003cb2 <iunlockput>
  end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	b6a080e7          	jalr	-1174(ra) # 80004492 <end_op>
  return 0;
    80005930:	4501                	li	a0,0
    80005932:	a84d                	j	800059e4 <sys_unlink+0x1c4>
    end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	b5e080e7          	jalr	-1186(ra) # 80004492 <end_op>
    return -1;
    8000593c:	557d                	li	a0,-1
    8000593e:	a05d                	j	800059e4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005940:	00003517          	auipc	a0,0x3
    80005944:	de050513          	addi	a0,a0,-544 # 80008720 <syscalls+0x2d0>
    80005948:	ffffb097          	auipc	ra,0xffffb
    8000594c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005950:	04c92703          	lw	a4,76(s2)
    80005954:	02000793          	li	a5,32
    80005958:	f6e7f9e3          	bgeu	a5,a4,800058ca <sys_unlink+0xaa>
    8000595c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005960:	4741                	li	a4,16
    80005962:	86ce                	mv	a3,s3
    80005964:	f1840613          	addi	a2,s0,-232
    80005968:	4581                	li	a1,0
    8000596a:	854a                	mv	a0,s2
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	398080e7          	jalr	920(ra) # 80003d04 <readi>
    80005974:	47c1                	li	a5,16
    80005976:	00f51b63          	bne	a0,a5,8000598c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000597a:	f1845783          	lhu	a5,-232(s0)
    8000597e:	e7a1                	bnez	a5,800059c6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005980:	29c1                	addiw	s3,s3,16
    80005982:	04c92783          	lw	a5,76(s2)
    80005986:	fcf9ede3          	bltu	s3,a5,80005960 <sys_unlink+0x140>
    8000598a:	b781                	j	800058ca <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000598c:	00003517          	auipc	a0,0x3
    80005990:	dac50513          	addi	a0,a0,-596 # 80008738 <syscalls+0x2e8>
    80005994:	ffffb097          	auipc	ra,0xffffb
    80005998:	baa080e7          	jalr	-1110(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000599c:	00003517          	auipc	a0,0x3
    800059a0:	db450513          	addi	a0,a0,-588 # 80008750 <syscalls+0x300>
    800059a4:	ffffb097          	auipc	ra,0xffffb
    800059a8:	b9a080e7          	jalr	-1126(ra) # 8000053e <panic>
    dp->nlink--;
    800059ac:	04a4d783          	lhu	a5,74(s1)
    800059b0:	37fd                	addiw	a5,a5,-1
    800059b2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	fce080e7          	jalr	-50(ra) # 80003986 <iupdate>
    800059c0:	b781                	j	80005900 <sys_unlink+0xe0>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	a005                	j	800059e4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059c6:	854a                	mv	a0,s2
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	2ea080e7          	jalr	746(ra) # 80003cb2 <iunlockput>
  iunlockput(dp);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	2e0080e7          	jalr	736(ra) # 80003cb2 <iunlockput>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	ab8080e7          	jalr	-1352(ra) # 80004492 <end_op>
  return -1;
    800059e2:	557d                	li	a0,-1
}
    800059e4:	70ae                	ld	ra,232(sp)
    800059e6:	740e                	ld	s0,224(sp)
    800059e8:	64ee                	ld	s1,216(sp)
    800059ea:	694e                	ld	s2,208(sp)
    800059ec:	69ae                	ld	s3,200(sp)
    800059ee:	616d                	addi	sp,sp,240
    800059f0:	8082                	ret

00000000800059f2 <sys_open>:

uint64
sys_open(void)
{
    800059f2:	7131                	addi	sp,sp,-192
    800059f4:	fd06                	sd	ra,184(sp)
    800059f6:	f922                	sd	s0,176(sp)
    800059f8:	f526                	sd	s1,168(sp)
    800059fa:	f14a                	sd	s2,160(sp)
    800059fc:	ed4e                	sd	s3,152(sp)
    800059fe:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a00:	f4c40593          	addi	a1,s0,-180
    80005a04:	4505                	li	a0,1
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	38e080e7          	jalr	910(ra) # 80002d94 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a0e:	08000613          	li	a2,128
    80005a12:	f5040593          	addi	a1,s0,-176
    80005a16:	4501                	li	a0,0
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	40a080e7          	jalr	1034(ra) # 80002e22 <argstr>
    80005a20:	87aa                	mv	a5,a0
    return -1;
    80005a22:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a24:	0a07c963          	bltz	a5,80005ad6 <sys_open+0xe4>

  begin_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	9ea080e7          	jalr	-1558(ra) # 80004412 <begin_op>

  if(omode & O_CREATE){
    80005a30:	f4c42783          	lw	a5,-180(s0)
    80005a34:	2007f793          	andi	a5,a5,512
    80005a38:	cfc5                	beqz	a5,80005af0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a3a:	4681                	li	a3,0
    80005a3c:	4601                	li	a2,0
    80005a3e:	4589                	li	a1,2
    80005a40:	f5040513          	addi	a0,s0,-176
    80005a44:	00000097          	auipc	ra,0x0
    80005a48:	976080e7          	jalr	-1674(ra) # 800053ba <create>
    80005a4c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a4e:	c959                	beqz	a0,80005ae4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a50:	04449703          	lh	a4,68(s1)
    80005a54:	478d                	li	a5,3
    80005a56:	00f71763          	bne	a4,a5,80005a64 <sys_open+0x72>
    80005a5a:	0464d703          	lhu	a4,70(s1)
    80005a5e:	47a5                	li	a5,9
    80005a60:	0ce7ed63          	bltu	a5,a4,80005b3a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	dbe080e7          	jalr	-578(ra) # 80004822 <filealloc>
    80005a6c:	89aa                	mv	s3,a0
    80005a6e:	10050363          	beqz	a0,80005b74 <sys_open+0x182>
    80005a72:	00000097          	auipc	ra,0x0
    80005a76:	906080e7          	jalr	-1786(ra) # 80005378 <fdalloc>
    80005a7a:	892a                	mv	s2,a0
    80005a7c:	0e054763          	bltz	a0,80005b6a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a80:	04449703          	lh	a4,68(s1)
    80005a84:	478d                	li	a5,3
    80005a86:	0cf70563          	beq	a4,a5,80005b50 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a8a:	4789                	li	a5,2
    80005a8c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a90:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a94:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a98:	f4c42783          	lw	a5,-180(s0)
    80005a9c:	0017c713          	xori	a4,a5,1
    80005aa0:	8b05                	andi	a4,a4,1
    80005aa2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005aa6:	0037f713          	andi	a4,a5,3
    80005aaa:	00e03733          	snez	a4,a4
    80005aae:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ab2:	4007f793          	andi	a5,a5,1024
    80005ab6:	c791                	beqz	a5,80005ac2 <sys_open+0xd0>
    80005ab8:	04449703          	lh	a4,68(s1)
    80005abc:	4789                	li	a5,2
    80005abe:	0af70063          	beq	a4,a5,80005b5e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	04e080e7          	jalr	78(ra) # 80003b12 <iunlock>
  end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	9c6080e7          	jalr	-1594(ra) # 80004492 <end_op>

  return fd;
    80005ad4:	854a                	mv	a0,s2
}
    80005ad6:	70ea                	ld	ra,184(sp)
    80005ad8:	744a                	ld	s0,176(sp)
    80005ada:	74aa                	ld	s1,168(sp)
    80005adc:	790a                	ld	s2,160(sp)
    80005ade:	69ea                	ld	s3,152(sp)
    80005ae0:	6129                	addi	sp,sp,192
    80005ae2:	8082                	ret
      end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	9ae080e7          	jalr	-1618(ra) # 80004492 <end_op>
      return -1;
    80005aec:	557d                	li	a0,-1
    80005aee:	b7e5                	j	80005ad6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005af0:	f5040513          	addi	a0,s0,-176
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	702080e7          	jalr	1794(ra) # 800041f6 <namei>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c905                	beqz	a0,80005b2e <sys_open+0x13c>
    ilock(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	f50080e7          	jalr	-176(ra) # 80003a50 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	4785                	li	a5,1
    80005b0e:	f4f711e3          	bne	a4,a5,80005a50 <sys_open+0x5e>
    80005b12:	f4c42783          	lw	a5,-180(s0)
    80005b16:	d7b9                	beqz	a5,80005a64 <sys_open+0x72>
      iunlockput(ip);
    80005b18:	8526                	mv	a0,s1
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	198080e7          	jalr	408(ra) # 80003cb2 <iunlockput>
      end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	970080e7          	jalr	-1680(ra) # 80004492 <end_op>
      return -1;
    80005b2a:	557d                	li	a0,-1
    80005b2c:	b76d                	j	80005ad6 <sys_open+0xe4>
      end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	964080e7          	jalr	-1692(ra) # 80004492 <end_op>
      return -1;
    80005b36:	557d                	li	a0,-1
    80005b38:	bf79                	j	80005ad6 <sys_open+0xe4>
    iunlockput(ip);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	176080e7          	jalr	374(ra) # 80003cb2 <iunlockput>
    end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	94e080e7          	jalr	-1714(ra) # 80004492 <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	b761                	j	80005ad6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b50:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b54:	04649783          	lh	a5,70(s1)
    80005b58:	02f99223          	sh	a5,36(s3)
    80005b5c:	bf25                	j	80005a94 <sys_open+0xa2>
    itrunc(ip);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	ffe080e7          	jalr	-2(ra) # 80003b5e <itrunc>
    80005b68:	bfa9                	j	80005ac2 <sys_open+0xd0>
      fileclose(f);
    80005b6a:	854e                	mv	a0,s3
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	d72080e7          	jalr	-654(ra) # 800048de <fileclose>
    iunlockput(ip);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	13c080e7          	jalr	316(ra) # 80003cb2 <iunlockput>
    end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	914080e7          	jalr	-1772(ra) # 80004492 <end_op>
    return -1;
    80005b86:	557d                	li	a0,-1
    80005b88:	b7b9                	j	80005ad6 <sys_open+0xe4>

0000000080005b8a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b8a:	7175                	addi	sp,sp,-144
    80005b8c:	e506                	sd	ra,136(sp)
    80005b8e:	e122                	sd	s0,128(sp)
    80005b90:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	880080e7          	jalr	-1920(ra) # 80004412 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b9a:	08000613          	li	a2,128
    80005b9e:	f7040593          	addi	a1,s0,-144
    80005ba2:	4501                	li	a0,0
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	27e080e7          	jalr	638(ra) # 80002e22 <argstr>
    80005bac:	02054963          	bltz	a0,80005bde <sys_mkdir+0x54>
    80005bb0:	4681                	li	a3,0
    80005bb2:	4601                	li	a2,0
    80005bb4:	4585                	li	a1,1
    80005bb6:	f7040513          	addi	a0,s0,-144
    80005bba:	00000097          	auipc	ra,0x0
    80005bbe:	800080e7          	jalr	-2048(ra) # 800053ba <create>
    80005bc2:	cd11                	beqz	a0,80005bde <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	0ee080e7          	jalr	238(ra) # 80003cb2 <iunlockput>
  end_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	8c6080e7          	jalr	-1850(ra) # 80004492 <end_op>
  return 0;
    80005bd4:	4501                	li	a0,0
}
    80005bd6:	60aa                	ld	ra,136(sp)
    80005bd8:	640a                	ld	s0,128(sp)
    80005bda:	6149                	addi	sp,sp,144
    80005bdc:	8082                	ret
    end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	8b4080e7          	jalr	-1868(ra) # 80004492 <end_op>
    return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	b7fd                	j	80005bd6 <sys_mkdir+0x4c>

0000000080005bea <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bea:	7135                	addi	sp,sp,-160
    80005bec:	ed06                	sd	ra,152(sp)
    80005bee:	e922                	sd	s0,144(sp)
    80005bf0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	820080e7          	jalr	-2016(ra) # 80004412 <begin_op>
  argint(1, &major);
    80005bfa:	f6c40593          	addi	a1,s0,-148
    80005bfe:	4505                	li	a0,1
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	194080e7          	jalr	404(ra) # 80002d94 <argint>
  argint(2, &minor);
    80005c08:	f6840593          	addi	a1,s0,-152
    80005c0c:	4509                	li	a0,2
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	186080e7          	jalr	390(ra) # 80002d94 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c16:	08000613          	li	a2,128
    80005c1a:	f7040593          	addi	a1,s0,-144
    80005c1e:	4501                	li	a0,0
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	202080e7          	jalr	514(ra) # 80002e22 <argstr>
    80005c28:	02054b63          	bltz	a0,80005c5e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c2c:	f6841683          	lh	a3,-152(s0)
    80005c30:	f6c41603          	lh	a2,-148(s0)
    80005c34:	458d                	li	a1,3
    80005c36:	f7040513          	addi	a0,s0,-144
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	780080e7          	jalr	1920(ra) # 800053ba <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c42:	cd11                	beqz	a0,80005c5e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	06e080e7          	jalr	110(ra) # 80003cb2 <iunlockput>
  end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	846080e7          	jalr	-1978(ra) # 80004492 <end_op>
  return 0;
    80005c54:	4501                	li	a0,0
}
    80005c56:	60ea                	ld	ra,152(sp)
    80005c58:	644a                	ld	s0,144(sp)
    80005c5a:	610d                	addi	sp,sp,160
    80005c5c:	8082                	ret
    end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	834080e7          	jalr	-1996(ra) # 80004492 <end_op>
    return -1;
    80005c66:	557d                	li	a0,-1
    80005c68:	b7fd                	j	80005c56 <sys_mknod+0x6c>

0000000080005c6a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c6a:	7135                	addi	sp,sp,-160
    80005c6c:	ed06                	sd	ra,152(sp)
    80005c6e:	e922                	sd	s0,144(sp)
    80005c70:	e526                	sd	s1,136(sp)
    80005c72:	e14a                	sd	s2,128(sp)
    80005c74:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c76:	ffffc097          	auipc	ra,0xffffc
    80005c7a:	d36080e7          	jalr	-714(ra) # 800019ac <myproc>
    80005c7e:	892a                	mv	s2,a0
  
  begin_op();
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	792080e7          	jalr	1938(ra) # 80004412 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c88:	08000613          	li	a2,128
    80005c8c:	f6040593          	addi	a1,s0,-160
    80005c90:	4501                	li	a0,0
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	190080e7          	jalr	400(ra) # 80002e22 <argstr>
    80005c9a:	04054b63          	bltz	a0,80005cf0 <sys_chdir+0x86>
    80005c9e:	f6040513          	addi	a0,s0,-160
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	554080e7          	jalr	1364(ra) # 800041f6 <namei>
    80005caa:	84aa                	mv	s1,a0
    80005cac:	c131                	beqz	a0,80005cf0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	da2080e7          	jalr	-606(ra) # 80003a50 <ilock>
  if(ip->type != T_DIR){
    80005cb6:	04449703          	lh	a4,68(s1)
    80005cba:	4785                	li	a5,1
    80005cbc:	04f71063          	bne	a4,a5,80005cfc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cc0:	8526                	mv	a0,s1
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	e50080e7          	jalr	-432(ra) # 80003b12 <iunlock>
  iput(p->cwd);
    80005cca:	17093503          	ld	a0,368(s2)
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	f3c080e7          	jalr	-196(ra) # 80003c0a <iput>
  end_op();
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	7bc080e7          	jalr	1980(ra) # 80004492 <end_op>
  p->cwd = ip;
    80005cde:	16993823          	sd	s1,368(s2)
  return 0;
    80005ce2:	4501                	li	a0,0
}
    80005ce4:	60ea                	ld	ra,152(sp)
    80005ce6:	644a                	ld	s0,144(sp)
    80005ce8:	64aa                	ld	s1,136(sp)
    80005cea:	690a                	ld	s2,128(sp)
    80005cec:	610d                	addi	sp,sp,160
    80005cee:	8082                	ret
    end_op();
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	7a2080e7          	jalr	1954(ra) # 80004492 <end_op>
    return -1;
    80005cf8:	557d                	li	a0,-1
    80005cfa:	b7ed                	j	80005ce4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cfc:	8526                	mv	a0,s1
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	fb4080e7          	jalr	-76(ra) # 80003cb2 <iunlockput>
    end_op();
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	78c080e7          	jalr	1932(ra) # 80004492 <end_op>
    return -1;
    80005d0e:	557d                	li	a0,-1
    80005d10:	bfd1                	j	80005ce4 <sys_chdir+0x7a>

0000000080005d12 <sys_exec>:

uint64
sys_exec(void)
{
    80005d12:	7145                	addi	sp,sp,-464
    80005d14:	e786                	sd	ra,456(sp)
    80005d16:	e3a2                	sd	s0,448(sp)
    80005d18:	ff26                	sd	s1,440(sp)
    80005d1a:	fb4a                	sd	s2,432(sp)
    80005d1c:	f74e                	sd	s3,424(sp)
    80005d1e:	f352                	sd	s4,416(sp)
    80005d20:	ef56                	sd	s5,408(sp)
    80005d22:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d24:	e3840593          	addi	a1,s0,-456
    80005d28:	4505                	li	a0,1
    80005d2a:	ffffd097          	auipc	ra,0xffffd
    80005d2e:	08a080e7          	jalr	138(ra) # 80002db4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d32:	08000613          	li	a2,128
    80005d36:	f4040593          	addi	a1,s0,-192
    80005d3a:	4501                	li	a0,0
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	0e6080e7          	jalr	230(ra) # 80002e22 <argstr>
    80005d44:	87aa                	mv	a5,a0
    return -1;
    80005d46:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d48:	0c07c263          	bltz	a5,80005e0c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d4c:	10000613          	li	a2,256
    80005d50:	4581                	li	a1,0
    80005d52:	e4040513          	addi	a0,s0,-448
    80005d56:	ffffb097          	auipc	ra,0xffffb
    80005d5a:	f7c080e7          	jalr	-132(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d5e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d62:	89a6                	mv	s3,s1
    80005d64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d66:	02000a13          	li	s4,32
    80005d6a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d6e:	00391793          	slli	a5,s2,0x3
    80005d72:	e3040593          	addi	a1,s0,-464
    80005d76:	e3843503          	ld	a0,-456(s0)
    80005d7a:	953e                	add	a0,a0,a5
    80005d7c:	ffffd097          	auipc	ra,0xffffd
    80005d80:	f7a080e7          	jalr	-134(ra) # 80002cf6 <fetchaddr>
    80005d84:	02054a63          	bltz	a0,80005db8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d88:	e3043783          	ld	a5,-464(s0)
    80005d8c:	c3b9                	beqz	a5,80005dd2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d8e:	ffffb097          	auipc	ra,0xffffb
    80005d92:	d58080e7          	jalr	-680(ra) # 80000ae6 <kalloc>
    80005d96:	85aa                	mv	a1,a0
    80005d98:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d9c:	cd11                	beqz	a0,80005db8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d9e:	6605                	lui	a2,0x1
    80005da0:	e3043503          	ld	a0,-464(s0)
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	fa4080e7          	jalr	-92(ra) # 80002d48 <fetchstr>
    80005dac:	00054663          	bltz	a0,80005db8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005db0:	0905                	addi	s2,s2,1
    80005db2:	09a1                	addi	s3,s3,8
    80005db4:	fb491be3          	bne	s2,s4,80005d6a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db8:	10048913          	addi	s2,s1,256
    80005dbc:	6088                	ld	a0,0(s1)
    80005dbe:	c531                	beqz	a0,80005e0a <sys_exec+0xf8>
    kfree(argv[i]);
    80005dc0:	ffffb097          	auipc	ra,0xffffb
    80005dc4:	c2a080e7          	jalr	-982(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc8:	04a1                	addi	s1,s1,8
    80005dca:	ff2499e3          	bne	s1,s2,80005dbc <sys_exec+0xaa>
  return -1;
    80005dce:	557d                	li	a0,-1
    80005dd0:	a835                	j	80005e0c <sys_exec+0xfa>
      argv[i] = 0;
    80005dd2:	0a8e                	slli	s5,s5,0x3
    80005dd4:	fc040793          	addi	a5,s0,-64
    80005dd8:	9abe                	add	s5,s5,a5
    80005dda:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005dde:	e4040593          	addi	a1,s0,-448
    80005de2:	f4040513          	addi	a0,s0,-192
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	172080e7          	jalr	370(ra) # 80004f58 <exec>
    80005dee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df0:	10048993          	addi	s3,s1,256
    80005df4:	6088                	ld	a0,0(s1)
    80005df6:	c901                	beqz	a0,80005e06 <sys_exec+0xf4>
    kfree(argv[i]);
    80005df8:	ffffb097          	auipc	ra,0xffffb
    80005dfc:	bf2080e7          	jalr	-1038(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e00:	04a1                	addi	s1,s1,8
    80005e02:	ff3499e3          	bne	s1,s3,80005df4 <sys_exec+0xe2>
  return ret;
    80005e06:	854a                	mv	a0,s2
    80005e08:	a011                	j	80005e0c <sys_exec+0xfa>
  return -1;
    80005e0a:	557d                	li	a0,-1
}
    80005e0c:	60be                	ld	ra,456(sp)
    80005e0e:	641e                	ld	s0,448(sp)
    80005e10:	74fa                	ld	s1,440(sp)
    80005e12:	795a                	ld	s2,432(sp)
    80005e14:	79ba                	ld	s3,424(sp)
    80005e16:	7a1a                	ld	s4,416(sp)
    80005e18:	6afa                	ld	s5,408(sp)
    80005e1a:	6179                	addi	sp,sp,464
    80005e1c:	8082                	ret

0000000080005e1e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e1e:	7139                	addi	sp,sp,-64
    80005e20:	fc06                	sd	ra,56(sp)
    80005e22:	f822                	sd	s0,48(sp)
    80005e24:	f426                	sd	s1,40(sp)
    80005e26:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b84080e7          	jalr	-1148(ra) # 800019ac <myproc>
    80005e30:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e32:	fd840593          	addi	a1,s0,-40
    80005e36:	4501                	li	a0,0
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	f7c080e7          	jalr	-132(ra) # 80002db4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e40:	fc840593          	addi	a1,s0,-56
    80005e44:	fd040513          	addi	a0,s0,-48
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	dc6080e7          	jalr	-570(ra) # 80004c0e <pipealloc>
    return -1;
    80005e50:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e52:	0c054463          	bltz	a0,80005f1a <sys_pipe+0xfc>
  fd0 = -1;
    80005e56:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e5a:	fd043503          	ld	a0,-48(s0)
    80005e5e:	fffff097          	auipc	ra,0xfffff
    80005e62:	51a080e7          	jalr	1306(ra) # 80005378 <fdalloc>
    80005e66:	fca42223          	sw	a0,-60(s0)
    80005e6a:	08054b63          	bltz	a0,80005f00 <sys_pipe+0xe2>
    80005e6e:	fc843503          	ld	a0,-56(s0)
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	506080e7          	jalr	1286(ra) # 80005378 <fdalloc>
    80005e7a:	fca42023          	sw	a0,-64(s0)
    80005e7e:	06054863          	bltz	a0,80005eee <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e82:	4691                	li	a3,4
    80005e84:	fc440613          	addi	a2,s0,-60
    80005e88:	fd843583          	ld	a1,-40(s0)
    80005e8c:	6ca8                	ld	a0,88(s1)
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	7da080e7          	jalr	2010(ra) # 80001668 <copyout>
    80005e96:	02054063          	bltz	a0,80005eb6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e9a:	4691                	li	a3,4
    80005e9c:	fc040613          	addi	a2,s0,-64
    80005ea0:	fd843583          	ld	a1,-40(s0)
    80005ea4:	0591                	addi	a1,a1,4
    80005ea6:	6ca8                	ld	a0,88(s1)
    80005ea8:	ffffb097          	auipc	ra,0xffffb
    80005eac:	7c0080e7          	jalr	1984(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005eb0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eb2:	06055463          	bgez	a0,80005f1a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005eb6:	fc442783          	lw	a5,-60(s0)
    80005eba:	07f9                	addi	a5,a5,30
    80005ebc:	078e                	slli	a5,a5,0x3
    80005ebe:	97a6                	add	a5,a5,s1
    80005ec0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ec4:	fc042503          	lw	a0,-64(s0)
    80005ec8:	0579                	addi	a0,a0,30
    80005eca:	050e                	slli	a0,a0,0x3
    80005ecc:	94aa                	add	s1,s1,a0
    80005ece:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ed2:	fd043503          	ld	a0,-48(s0)
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	a08080e7          	jalr	-1528(ra) # 800048de <fileclose>
    fileclose(wf);
    80005ede:	fc843503          	ld	a0,-56(s0)
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	9fc080e7          	jalr	-1540(ra) # 800048de <fileclose>
    return -1;
    80005eea:	57fd                	li	a5,-1
    80005eec:	a03d                	j	80005f1a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005eee:	fc442783          	lw	a5,-60(s0)
    80005ef2:	0007c763          	bltz	a5,80005f00 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ef6:	07f9                	addi	a5,a5,30
    80005ef8:	078e                	slli	a5,a5,0x3
    80005efa:	94be                	add	s1,s1,a5
    80005efc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f00:	fd043503          	ld	a0,-48(s0)
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	9da080e7          	jalr	-1574(ra) # 800048de <fileclose>
    fileclose(wf);
    80005f0c:	fc843503          	ld	a0,-56(s0)
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	9ce080e7          	jalr	-1586(ra) # 800048de <fileclose>
    return -1;
    80005f18:	57fd                	li	a5,-1
}
    80005f1a:	853e                	mv	a0,a5
    80005f1c:	70e2                	ld	ra,56(sp)
    80005f1e:	7442                	ld	s0,48(sp)
    80005f20:	74a2                	ld	s1,40(sp)
    80005f22:	6121                	addi	sp,sp,64
    80005f24:	8082                	ret
	...

0000000080005f30 <kernelvec>:
    80005f30:	7111                	addi	sp,sp,-256
    80005f32:	e006                	sd	ra,0(sp)
    80005f34:	e40a                	sd	sp,8(sp)
    80005f36:	e80e                	sd	gp,16(sp)
    80005f38:	ec12                	sd	tp,24(sp)
    80005f3a:	f016                	sd	t0,32(sp)
    80005f3c:	f41a                	sd	t1,40(sp)
    80005f3e:	f81e                	sd	t2,48(sp)
    80005f40:	fc22                	sd	s0,56(sp)
    80005f42:	e0a6                	sd	s1,64(sp)
    80005f44:	e4aa                	sd	a0,72(sp)
    80005f46:	e8ae                	sd	a1,80(sp)
    80005f48:	ecb2                	sd	a2,88(sp)
    80005f4a:	f0b6                	sd	a3,96(sp)
    80005f4c:	f4ba                	sd	a4,104(sp)
    80005f4e:	f8be                	sd	a5,112(sp)
    80005f50:	fcc2                	sd	a6,120(sp)
    80005f52:	e146                	sd	a7,128(sp)
    80005f54:	e54a                	sd	s2,136(sp)
    80005f56:	e94e                	sd	s3,144(sp)
    80005f58:	ed52                	sd	s4,152(sp)
    80005f5a:	f156                	sd	s5,160(sp)
    80005f5c:	f55a                	sd	s6,168(sp)
    80005f5e:	f95e                	sd	s7,176(sp)
    80005f60:	fd62                	sd	s8,184(sp)
    80005f62:	e1e6                	sd	s9,192(sp)
    80005f64:	e5ea                	sd	s10,200(sp)
    80005f66:	e9ee                	sd	s11,208(sp)
    80005f68:	edf2                	sd	t3,216(sp)
    80005f6a:	f1f6                	sd	t4,224(sp)
    80005f6c:	f5fa                	sd	t5,232(sp)
    80005f6e:	f9fe                	sd	t6,240(sp)
    80005f70:	c0bfc0ef          	jal	ra,80002b7a <kerneltrap>
    80005f74:	6082                	ld	ra,0(sp)
    80005f76:	6122                	ld	sp,8(sp)
    80005f78:	61c2                	ld	gp,16(sp)
    80005f7a:	7282                	ld	t0,32(sp)
    80005f7c:	7322                	ld	t1,40(sp)
    80005f7e:	73c2                	ld	t2,48(sp)
    80005f80:	7462                	ld	s0,56(sp)
    80005f82:	6486                	ld	s1,64(sp)
    80005f84:	6526                	ld	a0,72(sp)
    80005f86:	65c6                	ld	a1,80(sp)
    80005f88:	6666                	ld	a2,88(sp)
    80005f8a:	7686                	ld	a3,96(sp)
    80005f8c:	7726                	ld	a4,104(sp)
    80005f8e:	77c6                	ld	a5,112(sp)
    80005f90:	7866                	ld	a6,120(sp)
    80005f92:	688a                	ld	a7,128(sp)
    80005f94:	692a                	ld	s2,136(sp)
    80005f96:	69ca                	ld	s3,144(sp)
    80005f98:	6a6a                	ld	s4,152(sp)
    80005f9a:	7a8a                	ld	s5,160(sp)
    80005f9c:	7b2a                	ld	s6,168(sp)
    80005f9e:	7bca                	ld	s7,176(sp)
    80005fa0:	7c6a                	ld	s8,184(sp)
    80005fa2:	6c8e                	ld	s9,192(sp)
    80005fa4:	6d2e                	ld	s10,200(sp)
    80005fa6:	6dce                	ld	s11,208(sp)
    80005fa8:	6e6e                	ld	t3,216(sp)
    80005faa:	7e8e                	ld	t4,224(sp)
    80005fac:	7f2e                	ld	t5,232(sp)
    80005fae:	7fce                	ld	t6,240(sp)
    80005fb0:	6111                	addi	sp,sp,256
    80005fb2:	10200073          	sret
    80005fb6:	00000013          	nop
    80005fba:	00000013          	nop
    80005fbe:	0001                	nop

0000000080005fc0 <timervec>:
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	e10c                	sd	a1,0(a0)
    80005fc6:	e510                	sd	a2,8(a0)
    80005fc8:	e914                	sd	a3,16(a0)
    80005fca:	6d0c                	ld	a1,24(a0)
    80005fcc:	7110                	ld	a2,32(a0)
    80005fce:	6194                	ld	a3,0(a1)
    80005fd0:	96b2                	add	a3,a3,a2
    80005fd2:	e194                	sd	a3,0(a1)
    80005fd4:	4589                	li	a1,2
    80005fd6:	14459073          	csrw	sip,a1
    80005fda:	6914                	ld	a3,16(a0)
    80005fdc:	6510                	ld	a2,8(a0)
    80005fde:	610c                	ld	a1,0(a0)
    80005fe0:	34051573          	csrrw	a0,mscratch,a0
    80005fe4:	30200073          	mret
	...

0000000080005fea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fea:	1141                	addi	sp,sp,-16
    80005fec:	e422                	sd	s0,8(sp)
    80005fee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ff0:	0c0007b7          	lui	a5,0xc000
    80005ff4:	4705                	li	a4,1
    80005ff6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ff8:	c3d8                	sw	a4,4(a5)
}
    80005ffa:	6422                	ld	s0,8(sp)
    80005ffc:	0141                	addi	sp,sp,16
    80005ffe:	8082                	ret

0000000080006000 <plicinithart>:

void
plicinithart(void)
{
    80006000:	1141                	addi	sp,sp,-16
    80006002:	e406                	sd	ra,8(sp)
    80006004:	e022                	sd	s0,0(sp)
    80006006:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	978080e7          	jalr	-1672(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006010:	0085171b          	slliw	a4,a0,0x8
    80006014:	0c0027b7          	lui	a5,0xc002
    80006018:	97ba                	add	a5,a5,a4
    8000601a:	40200713          	li	a4,1026
    8000601e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006022:	00d5151b          	slliw	a0,a0,0xd
    80006026:	0c2017b7          	lui	a5,0xc201
    8000602a:	953e                	add	a0,a0,a5
    8000602c:	00052023          	sw	zero,0(a0)
}
    80006030:	60a2                	ld	ra,8(sp)
    80006032:	6402                	ld	s0,0(sp)
    80006034:	0141                	addi	sp,sp,16
    80006036:	8082                	ret

0000000080006038 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006038:	1141                	addi	sp,sp,-16
    8000603a:	e406                	sd	ra,8(sp)
    8000603c:	e022                	sd	s0,0(sp)
    8000603e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006040:	ffffc097          	auipc	ra,0xffffc
    80006044:	940080e7          	jalr	-1728(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006048:	00d5179b          	slliw	a5,a0,0xd
    8000604c:	0c201537          	lui	a0,0xc201
    80006050:	953e                	add	a0,a0,a5
  return irq;
}
    80006052:	4148                	lw	a0,4(a0)
    80006054:	60a2                	ld	ra,8(sp)
    80006056:	6402                	ld	s0,0(sp)
    80006058:	0141                	addi	sp,sp,16
    8000605a:	8082                	ret

000000008000605c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000605c:	1101                	addi	sp,sp,-32
    8000605e:	ec06                	sd	ra,24(sp)
    80006060:	e822                	sd	s0,16(sp)
    80006062:	e426                	sd	s1,8(sp)
    80006064:	1000                	addi	s0,sp,32
    80006066:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	918080e7          	jalr	-1768(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006070:	00d5151b          	slliw	a0,a0,0xd
    80006074:	0c2017b7          	lui	a5,0xc201
    80006078:	97aa                	add	a5,a5,a0
    8000607a:	c3c4                	sw	s1,4(a5)
}
    8000607c:	60e2                	ld	ra,24(sp)
    8000607e:	6442                	ld	s0,16(sp)
    80006080:	64a2                	ld	s1,8(sp)
    80006082:	6105                	addi	sp,sp,32
    80006084:	8082                	ret

0000000080006086 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006086:	1141                	addi	sp,sp,-16
    80006088:	e406                	sd	ra,8(sp)
    8000608a:	e022                	sd	s0,0(sp)
    8000608c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000608e:	479d                	li	a5,7
    80006090:	04a7cc63          	blt	a5,a0,800060e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006094:	0001c797          	auipc	a5,0x1c
    80006098:	78c78793          	addi	a5,a5,1932 # 80022820 <disk>
    8000609c:	97aa                	add	a5,a5,a0
    8000609e:	0187c783          	lbu	a5,24(a5)
    800060a2:	ebb9                	bnez	a5,800060f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060a4:	00451613          	slli	a2,a0,0x4
    800060a8:	0001c797          	auipc	a5,0x1c
    800060ac:	77878793          	addi	a5,a5,1912 # 80022820 <disk>
    800060b0:	6394                	ld	a3,0(a5)
    800060b2:	96b2                	add	a3,a3,a2
    800060b4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800060b8:	6398                	ld	a4,0(a5)
    800060ba:	9732                	add	a4,a4,a2
    800060bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060c8:	953e                	add	a0,a0,a5
    800060ca:	4785                	li	a5,1
    800060cc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800060d0:	0001c517          	auipc	a0,0x1c
    800060d4:	76850513          	addi	a0,a0,1896 # 80022838 <disk+0x18>
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	070080e7          	jalr	112(ra) # 80002148 <wakeup>
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret
    panic("free_desc 1");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	67850513          	addi	a0,a0,1656 # 80008760 <syscalls+0x310>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	44e080e7          	jalr	1102(ra) # 8000053e <panic>
    panic("free_desc 2");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	67850513          	addi	a0,a0,1656 # 80008770 <syscalls+0x320>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>

0000000080006108 <virtio_disk_init>:
{
    80006108:	1101                	addi	sp,sp,-32
    8000610a:	ec06                	sd	ra,24(sp)
    8000610c:	e822                	sd	s0,16(sp)
    8000610e:	e426                	sd	s1,8(sp)
    80006110:	e04a                	sd	s2,0(sp)
    80006112:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006114:	00002597          	auipc	a1,0x2
    80006118:	66c58593          	addi	a1,a1,1644 # 80008780 <syscalls+0x330>
    8000611c:	0001d517          	auipc	a0,0x1d
    80006120:	82c50513          	addi	a0,a0,-2004 # 80022948 <disk+0x128>
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	a22080e7          	jalr	-1502(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000612c:	100017b7          	lui	a5,0x10001
    80006130:	4398                	lw	a4,0(a5)
    80006132:	2701                	sext.w	a4,a4
    80006134:	747277b7          	lui	a5,0x74727
    80006138:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000613c:	14f71c63          	bne	a4,a5,80006294 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006140:	100017b7          	lui	a5,0x10001
    80006144:	43dc                	lw	a5,4(a5)
    80006146:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006148:	4709                	li	a4,2
    8000614a:	14e79563          	bne	a5,a4,80006294 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000614e:	100017b7          	lui	a5,0x10001
    80006152:	479c                	lw	a5,8(a5)
    80006154:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006156:	12e79f63          	bne	a5,a4,80006294 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000615a:	100017b7          	lui	a5,0x10001
    8000615e:	47d8                	lw	a4,12(a5)
    80006160:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006162:	554d47b7          	lui	a5,0x554d4
    80006166:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000616a:	12f71563          	bne	a4,a5,80006294 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616e:	100017b7          	lui	a5,0x10001
    80006172:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006176:	4705                	li	a4,1
    80006178:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000617a:	470d                	li	a4,3
    8000617c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000617e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006180:	c7ffe737          	lui	a4,0xc7ffe
    80006184:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbdff>
    80006188:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000618a:	2701                	sext.w	a4,a4
    8000618c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000618e:	472d                	li	a4,11
    80006190:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006192:	5bbc                	lw	a5,112(a5)
    80006194:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006198:	8ba1                	andi	a5,a5,8
    8000619a:	10078563          	beqz	a5,800062a4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000619e:	100017b7          	lui	a5,0x10001
    800061a2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800061a6:	43fc                	lw	a5,68(a5)
    800061a8:	2781                	sext.w	a5,a5
    800061aa:	10079563          	bnez	a5,800062b4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061ae:	100017b7          	lui	a5,0x10001
    800061b2:	5bdc                	lw	a5,52(a5)
    800061b4:	2781                	sext.w	a5,a5
  if(max == 0)
    800061b6:	10078763          	beqz	a5,800062c4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800061ba:	471d                	li	a4,7
    800061bc:	10f77c63          	bgeu	a4,a5,800062d4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	926080e7          	jalr	-1754(ra) # 80000ae6 <kalloc>
    800061c8:	0001c497          	auipc	s1,0x1c
    800061cc:	65848493          	addi	s1,s1,1624 # 80022820 <disk>
    800061d0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061d2:	ffffb097          	auipc	ra,0xffffb
    800061d6:	914080e7          	jalr	-1772(ra) # 80000ae6 <kalloc>
    800061da:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	90a080e7          	jalr	-1782(ra) # 80000ae6 <kalloc>
    800061e4:	87aa                	mv	a5,a0
    800061e6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061e8:	6088                	ld	a0,0(s1)
    800061ea:	cd6d                	beqz	a0,800062e4 <virtio_disk_init+0x1dc>
    800061ec:	0001c717          	auipc	a4,0x1c
    800061f0:	63c73703          	ld	a4,1596(a4) # 80022828 <disk+0x8>
    800061f4:	cb65                	beqz	a4,800062e4 <virtio_disk_init+0x1dc>
    800061f6:	c7fd                	beqz	a5,800062e4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800061f8:	6605                	lui	a2,0x1
    800061fa:	4581                	li	a1,0
    800061fc:	ffffb097          	auipc	ra,0xffffb
    80006200:	ad6080e7          	jalr	-1322(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006204:	0001c497          	auipc	s1,0x1c
    80006208:	61c48493          	addi	s1,s1,1564 # 80022820 <disk>
    8000620c:	6605                	lui	a2,0x1
    8000620e:	4581                	li	a1,0
    80006210:	6488                	ld	a0,8(s1)
    80006212:	ffffb097          	auipc	ra,0xffffb
    80006216:	ac0080e7          	jalr	-1344(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000621a:	6605                	lui	a2,0x1
    8000621c:	4581                	li	a1,0
    8000621e:	6888                	ld	a0,16(s1)
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	ab2080e7          	jalr	-1358(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006228:	100017b7          	lui	a5,0x10001
    8000622c:	4721                	li	a4,8
    8000622e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006230:	4098                	lw	a4,0(s1)
    80006232:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006236:	40d8                	lw	a4,4(s1)
    80006238:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000623c:	6498                	ld	a4,8(s1)
    8000623e:	0007069b          	sext.w	a3,a4
    80006242:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006246:	9701                	srai	a4,a4,0x20
    80006248:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000624c:	6898                	ld	a4,16(s1)
    8000624e:	0007069b          	sext.w	a3,a4
    80006252:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006256:	9701                	srai	a4,a4,0x20
    80006258:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000625c:	4705                	li	a4,1
    8000625e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006260:	00e48c23          	sb	a4,24(s1)
    80006264:	00e48ca3          	sb	a4,25(s1)
    80006268:	00e48d23          	sb	a4,26(s1)
    8000626c:	00e48da3          	sb	a4,27(s1)
    80006270:	00e48e23          	sb	a4,28(s1)
    80006274:	00e48ea3          	sb	a4,29(s1)
    80006278:	00e48f23          	sb	a4,30(s1)
    8000627c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006280:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006284:	0727a823          	sw	s2,112(a5)
}
    80006288:	60e2                	ld	ra,24(sp)
    8000628a:	6442                	ld	s0,16(sp)
    8000628c:	64a2                	ld	s1,8(sp)
    8000628e:	6902                	ld	s2,0(sp)
    80006290:	6105                	addi	sp,sp,32
    80006292:	8082                	ret
    panic("could not find virtio disk");
    80006294:	00002517          	auipc	a0,0x2
    80006298:	4fc50513          	addi	a0,a0,1276 # 80008790 <syscalls+0x340>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	50c50513          	addi	a0,a0,1292 # 800087b0 <syscalls+0x360>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800062b4:	00002517          	auipc	a0,0x2
    800062b8:	51c50513          	addi	a0,a0,1308 # 800087d0 <syscalls+0x380>
    800062bc:	ffffa097          	auipc	ra,0xffffa
    800062c0:	282080e7          	jalr	642(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	52c50513          	addi	a0,a0,1324 # 800087f0 <syscalls+0x3a0>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062d4:	00002517          	auipc	a0,0x2
    800062d8:	53c50513          	addi	a0,a0,1340 # 80008810 <syscalls+0x3c0>
    800062dc:	ffffa097          	auipc	ra,0xffffa
    800062e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	54c50513          	addi	a0,a0,1356 # 80008830 <syscalls+0x3e0>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	252080e7          	jalr	594(ra) # 8000053e <panic>

00000000800062f4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062f4:	7119                	addi	sp,sp,-128
    800062f6:	fc86                	sd	ra,120(sp)
    800062f8:	f8a2                	sd	s0,112(sp)
    800062fa:	f4a6                	sd	s1,104(sp)
    800062fc:	f0ca                	sd	s2,96(sp)
    800062fe:	ecce                	sd	s3,88(sp)
    80006300:	e8d2                	sd	s4,80(sp)
    80006302:	e4d6                	sd	s5,72(sp)
    80006304:	e0da                	sd	s6,64(sp)
    80006306:	fc5e                	sd	s7,56(sp)
    80006308:	f862                	sd	s8,48(sp)
    8000630a:	f466                	sd	s9,40(sp)
    8000630c:	f06a                	sd	s10,32(sp)
    8000630e:	ec6e                	sd	s11,24(sp)
    80006310:	0100                	addi	s0,sp,128
    80006312:	8aaa                	mv	s5,a0
    80006314:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006316:	00c52d03          	lw	s10,12(a0)
    8000631a:	001d1d1b          	slliw	s10,s10,0x1
    8000631e:	1d02                	slli	s10,s10,0x20
    80006320:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006324:	0001c517          	auipc	a0,0x1c
    80006328:	62450513          	addi	a0,a0,1572 # 80022948 <disk+0x128>
    8000632c:	ffffb097          	auipc	ra,0xffffb
    80006330:	8aa080e7          	jalr	-1878(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006334:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006336:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006338:	0001cb97          	auipc	s7,0x1c
    8000633c:	4e8b8b93          	addi	s7,s7,1256 # 80022820 <disk>
  for(int i = 0; i < 3; i++){
    80006340:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006342:	0001cc97          	auipc	s9,0x1c
    80006346:	606c8c93          	addi	s9,s9,1542 # 80022948 <disk+0x128>
    8000634a:	a08d                	j	800063ac <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000634c:	00fb8733          	add	a4,s7,a5
    80006350:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006354:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006356:	0207c563          	bltz	a5,80006380 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000635a:	2905                	addiw	s2,s2,1
    8000635c:	0611                	addi	a2,a2,4
    8000635e:	05690c63          	beq	s2,s6,800063b6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006362:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006364:	0001c717          	auipc	a4,0x1c
    80006368:	4bc70713          	addi	a4,a4,1212 # 80022820 <disk>
    8000636c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000636e:	01874683          	lbu	a3,24(a4)
    80006372:	fee9                	bnez	a3,8000634c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006374:	2785                	addiw	a5,a5,1
    80006376:	0705                	addi	a4,a4,1
    80006378:	fe979be3          	bne	a5,s1,8000636e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000637c:	57fd                	li	a5,-1
    8000637e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006380:	01205d63          	blez	s2,8000639a <virtio_disk_rw+0xa6>
    80006384:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006386:	000a2503          	lw	a0,0(s4)
    8000638a:	00000097          	auipc	ra,0x0
    8000638e:	cfc080e7          	jalr	-772(ra) # 80006086 <free_desc>
      for(int j = 0; j < i; j++)
    80006392:	2d85                	addiw	s11,s11,1
    80006394:	0a11                	addi	s4,s4,4
    80006396:	ffb918e3          	bne	s2,s11,80006386 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000639a:	85e6                	mv	a1,s9
    8000639c:	0001c517          	auipc	a0,0x1c
    800063a0:	49c50513          	addi	a0,a0,1180 # 80022838 <disk+0x18>
    800063a4:	ffffc097          	auipc	ra,0xffffc
    800063a8:	d40080e7          	jalr	-704(ra) # 800020e4 <sleep>
  for(int i = 0; i < 3; i++){
    800063ac:	f8040a13          	addi	s4,s0,-128
{
    800063b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063b2:	894e                	mv	s2,s3
    800063b4:	b77d                	j	80006362 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063b6:	f8042583          	lw	a1,-128(s0)
    800063ba:	00a58793          	addi	a5,a1,10
    800063be:	0792                	slli	a5,a5,0x4

  if(write)
    800063c0:	0001c617          	auipc	a2,0x1c
    800063c4:	46060613          	addi	a2,a2,1120 # 80022820 <disk>
    800063c8:	00f60733          	add	a4,a2,a5
    800063cc:	018036b3          	snez	a3,s8
    800063d0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800063d6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063da:	f6078693          	addi	a3,a5,-160
    800063de:	6218                	ld	a4,0(a2)
    800063e0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063e2:	00878513          	addi	a0,a5,8
    800063e6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063e8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063ea:	6208                	ld	a0,0(a2)
    800063ec:	96aa                	add	a3,a3,a0
    800063ee:	4741                	li	a4,16
    800063f0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063f2:	4705                	li	a4,1
    800063f4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800063f8:	f8442703          	lw	a4,-124(s0)
    800063fc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006400:	0712                	slli	a4,a4,0x4
    80006402:	953a                	add	a0,a0,a4
    80006404:	058a8693          	addi	a3,s5,88
    80006408:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000640a:	6208                	ld	a0,0(a2)
    8000640c:	972a                	add	a4,a4,a0
    8000640e:	40000693          	li	a3,1024
    80006412:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006414:	001c3c13          	seqz	s8,s8
    80006418:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000641a:	001c6c13          	ori	s8,s8,1
    8000641e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006422:	f8842603          	lw	a2,-120(s0)
    80006426:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000642a:	0001c697          	auipc	a3,0x1c
    8000642e:	3f668693          	addi	a3,a3,1014 # 80022820 <disk>
    80006432:	00258713          	addi	a4,a1,2
    80006436:	0712                	slli	a4,a4,0x4
    80006438:	9736                	add	a4,a4,a3
    8000643a:	587d                	li	a6,-1
    8000643c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006440:	0612                	slli	a2,a2,0x4
    80006442:	9532                	add	a0,a0,a2
    80006444:	f9078793          	addi	a5,a5,-112
    80006448:	97b6                	add	a5,a5,a3
    8000644a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000644c:	629c                	ld	a5,0(a3)
    8000644e:	97b2                	add	a5,a5,a2
    80006450:	4605                	li	a2,1
    80006452:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006454:	4509                	li	a0,2
    80006456:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000645a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000645e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006462:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006466:	6698                	ld	a4,8(a3)
    80006468:	00275783          	lhu	a5,2(a4)
    8000646c:	8b9d                	andi	a5,a5,7
    8000646e:	0786                	slli	a5,a5,0x1
    80006470:	97ba                	add	a5,a5,a4
    80006472:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006476:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000647a:	6698                	ld	a4,8(a3)
    8000647c:	00275783          	lhu	a5,2(a4)
    80006480:	2785                	addiw	a5,a5,1
    80006482:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006486:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000648a:	100017b7          	lui	a5,0x10001
    8000648e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006492:	004aa783          	lw	a5,4(s5)
    80006496:	02c79163          	bne	a5,a2,800064b8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000649a:	0001c917          	auipc	s2,0x1c
    8000649e:	4ae90913          	addi	s2,s2,1198 # 80022948 <disk+0x128>
  while(b->disk == 1) {
    800064a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064a4:	85ca                	mv	a1,s2
    800064a6:	8556                	mv	a0,s5
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	c3c080e7          	jalr	-964(ra) # 800020e4 <sleep>
  while(b->disk == 1) {
    800064b0:	004aa783          	lw	a5,4(s5)
    800064b4:	fe9788e3          	beq	a5,s1,800064a4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064b8:	f8042903          	lw	s2,-128(s0)
    800064bc:	00290793          	addi	a5,s2,2
    800064c0:	00479713          	slli	a4,a5,0x4
    800064c4:	0001c797          	auipc	a5,0x1c
    800064c8:	35c78793          	addi	a5,a5,860 # 80022820 <disk>
    800064cc:	97ba                	add	a5,a5,a4
    800064ce:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064d2:	0001c997          	auipc	s3,0x1c
    800064d6:	34e98993          	addi	s3,s3,846 # 80022820 <disk>
    800064da:	00491713          	slli	a4,s2,0x4
    800064de:	0009b783          	ld	a5,0(s3)
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064e8:	854a                	mv	a0,s2
    800064ea:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064ee:	00000097          	auipc	ra,0x0
    800064f2:	b98080e7          	jalr	-1128(ra) # 80006086 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064f6:	8885                	andi	s1,s1,1
    800064f8:	f0ed                	bnez	s1,800064da <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064fa:	0001c517          	auipc	a0,0x1c
    800064fe:	44e50513          	addi	a0,a0,1102 # 80022948 <disk+0x128>
    80006502:	ffffa097          	auipc	ra,0xffffa
    80006506:	788080e7          	jalr	1928(ra) # 80000c8a <release>
}
    8000650a:	70e6                	ld	ra,120(sp)
    8000650c:	7446                	ld	s0,112(sp)
    8000650e:	74a6                	ld	s1,104(sp)
    80006510:	7906                	ld	s2,96(sp)
    80006512:	69e6                	ld	s3,88(sp)
    80006514:	6a46                	ld	s4,80(sp)
    80006516:	6aa6                	ld	s5,72(sp)
    80006518:	6b06                	ld	s6,64(sp)
    8000651a:	7be2                	ld	s7,56(sp)
    8000651c:	7c42                	ld	s8,48(sp)
    8000651e:	7ca2                	ld	s9,40(sp)
    80006520:	7d02                	ld	s10,32(sp)
    80006522:	6de2                	ld	s11,24(sp)
    80006524:	6109                	addi	sp,sp,128
    80006526:	8082                	ret

0000000080006528 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006528:	1101                	addi	sp,sp,-32
    8000652a:	ec06                	sd	ra,24(sp)
    8000652c:	e822                	sd	s0,16(sp)
    8000652e:	e426                	sd	s1,8(sp)
    80006530:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006532:	0001c497          	auipc	s1,0x1c
    80006536:	2ee48493          	addi	s1,s1,750 # 80022820 <disk>
    8000653a:	0001c517          	auipc	a0,0x1c
    8000653e:	40e50513          	addi	a0,a0,1038 # 80022948 <disk+0x128>
    80006542:	ffffa097          	auipc	ra,0xffffa
    80006546:	694080e7          	jalr	1684(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000654a:	10001737          	lui	a4,0x10001
    8000654e:	533c                	lw	a5,96(a4)
    80006550:	8b8d                	andi	a5,a5,3
    80006552:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006554:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006558:	689c                	ld	a5,16(s1)
    8000655a:	0204d703          	lhu	a4,32(s1)
    8000655e:	0027d783          	lhu	a5,2(a5)
    80006562:	04f70863          	beq	a4,a5,800065b2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006566:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000656a:	6898                	ld	a4,16(s1)
    8000656c:	0204d783          	lhu	a5,32(s1)
    80006570:	8b9d                	andi	a5,a5,7
    80006572:	078e                	slli	a5,a5,0x3
    80006574:	97ba                	add	a5,a5,a4
    80006576:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006578:	00278713          	addi	a4,a5,2
    8000657c:	0712                	slli	a4,a4,0x4
    8000657e:	9726                	add	a4,a4,s1
    80006580:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006584:	e721                	bnez	a4,800065cc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006586:	0789                	addi	a5,a5,2
    80006588:	0792                	slli	a5,a5,0x4
    8000658a:	97a6                	add	a5,a5,s1
    8000658c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000658e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006592:	ffffc097          	auipc	ra,0xffffc
    80006596:	bb6080e7          	jalr	-1098(ra) # 80002148 <wakeup>

    disk.used_idx += 1;
    8000659a:	0204d783          	lhu	a5,32(s1)
    8000659e:	2785                	addiw	a5,a5,1
    800065a0:	17c2                	slli	a5,a5,0x30
    800065a2:	93c1                	srli	a5,a5,0x30
    800065a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065a8:	6898                	ld	a4,16(s1)
    800065aa:	00275703          	lhu	a4,2(a4)
    800065ae:	faf71ce3          	bne	a4,a5,80006566 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065b2:	0001c517          	auipc	a0,0x1c
    800065b6:	39650513          	addi	a0,a0,918 # 80022948 <disk+0x128>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	6d0080e7          	jalr	1744(ra) # 80000c8a <release>
}
    800065c2:	60e2                	ld	ra,24(sp)
    800065c4:	6442                	ld	s0,16(sp)
    800065c6:	64a2                	ld	s1,8(sp)
    800065c8:	6105                	addi	sp,sp,32
    800065ca:	8082                	ret
      panic("virtio_disk_intr status");
    800065cc:	00002517          	auipc	a0,0x2
    800065d0:	27c50513          	addi	a0,a0,636 # 80008848 <syscalls+0x3f8>
    800065d4:	ffffa097          	auipc	ra,0xffffa
    800065d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>
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
