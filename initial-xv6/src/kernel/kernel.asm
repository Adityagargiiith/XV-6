
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
    80000068:	ecc78793          	addi	a5,a5,-308 # 80005f30 <timervec>
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
    80000130:	3ba080e7          	jalr	954(ra) # 800024e6 <either_copyin>
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
    800001cc:	168080e7          	jalr	360(ra) # 80002330 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ea6080e7          	jalr	-346(ra) # 8000207c <sleep>
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
    80000216:	27e080e7          	jalr	638(ra) # 80002490 <either_copyout>
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
    800002f6:	24a080e7          	jalr	586(ra) # 8000253c <procdump>
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
    8000044a:	c9a080e7          	jalr	-870(ra) # 800020e0 <wakeup>
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
    80000896:	84e080e7          	jalr	-1970(ra) # 800020e0 <wakeup>
    
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
    80000920:	760080e7          	jalr	1888(ra) # 8000207c <sleep>
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
    80000ec2:	968080e7          	jalr	-1688(ra) # 80002826 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0aa080e7          	jalr	170(ra) # 80005f70 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	ffc080e7          	jalr	-4(ra) # 80001eca <scheduler>
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
    80000f3a:	8c8080e7          	jalr	-1848(ra) # 800027fe <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	8e8080e7          	jalr	-1816(ra) # 80002826 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	014080e7          	jalr	20(ra) # 80005f5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	022080e7          	jalr	34(ra) # 80005f70 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1c8080e7          	jalr	456(ra) # 8000311e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	86c080e7          	jalr	-1940(ra) # 800037ca <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	80a080e7          	jalr	-2038(ra) # 80004770 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	10a080e7          	jalr	266(ra) # 80006078 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d36080e7          	jalr	-714(ra) # 80001cac <userinit>
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
    80001a0a:	e38080e7          	jalr	-456(ra) # 8000283e <usertrapret>
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
    80001a24:	d2a080e7          	jalr	-726(ra) # 8000374a <fsinit>
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
    80001bcc:	c14d                	beqz	a0,80001c6e <allocproc+0xb8>
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
    80001c04:	a0ad                	j	80001c6e <allocproc+0xb8>
  p->pid = allocpid();
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	e24080e7          	jalr	-476(ra) # 80001a2a <allocpid>
    80001c0e:	d888                	sw	a0,48(s1)
  p->readcount=0;    //Initializing read count to 0
    80001c10:	0204aa23          	sw	zero,52(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	ece080e7          	jalr	-306(ra) # 80000ae6 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	f0a8                	sd	a0,96(s1)
    80001c24:	cd21                	beqz	a0,80001c7c <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e48080e7          	jalr	-440(ra) # 80001a70 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001c34:	c125                	beqz	a0,80001c94 <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	08048513          	addi	a0,s1,128
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	092080e7          	jalr	146(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	d9c78793          	addi	a5,a5,-612 # 800019e4 <forkret>
    80001c50:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	e4dc                	sd	a5,136(s1)
  p->rtime = 0;
    80001c5a:	1804a423          	sw	zero,392(s1)
  p->etime = 0;
    80001c5e:	1804a823          	sw	zero,400(s1)
  p->ctime = ticks;
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	c7e7a783          	lw	a5,-898(a5) # 800088e0 <ticks>
    80001c6a:	18f4a623          	sw	a5,396(s1)
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ee0080e7          	jalr	-288(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	002080e7          	jalr	2(ra) # 80000c8a <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	bff1                	j	80001c6e <allocproc+0xb8>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	ec8080e7          	jalr	-312(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fea080e7          	jalr	-22(ra) # 80000c8a <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7d1                	j	80001c6e <allocproc+0xb8>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f00080e7          	jalr	-256(ra) # 80001bb6 <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	c0a7bc23          	sd	a0,-1000(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	ba458593          	addi	a1,a1,-1116 # 80008870 <initcode>
    80001cd4:	6d28                	ld	a0,88(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	680080e7          	jalr	1664(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce2:	70b8                	ld	a4,96(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce8:	70b8                	ld	a4,96(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	51258593          	addi	a1,a1,1298 # 80008200 <digits+0x1c0>
    80001cf6:	17848513          	addi	a0,s1,376
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	122080e7          	jalr	290(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	50e50513          	addi	a0,a0,1294 # 80008210 <digits+0x1d0>
    80001d0a:	00002097          	auipc	ra,0x2
    80001d0e:	462080e7          	jalr	1122(ra) # 8000416c <namei>
    80001d12:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d16:	478d                	li	a5,3
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f6e080e7          	jalr	-146(ra) # 80000c8a <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c70080e7          	jalr	-912(ra) # 800019ac <myproc>
    80001d44:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d46:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d48:	01204c63          	bgtz	s2,80001d60 <growproc+0x32>
  else if (n < 0)
    80001d4c:	02094663          	bltz	s2,80001d78 <growproc+0x4a>
  p->sz = sz;
    80001d50:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d52:	4501                	li	a0,0
}
    80001d54:	60e2                	ld	ra,24(sp)
    80001d56:	6442                	ld	s0,16(sp)
    80001d58:	64a2                	ld	s1,8(sp)
    80001d5a:	6902                	ld	s2,0(sp)
    80001d5c:	6105                	addi	sp,sp,32
    80001d5e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d60:	4691                	li	a3,4
    80001d62:	00b90633          	add	a2,s2,a1
    80001d66:	6d28                	ld	a0,88(a0)
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	6a8080e7          	jalr	1704(ra) # 80001410 <uvmalloc>
    80001d70:	85aa                	mv	a1,a0
    80001d72:	fd79                	bnez	a0,80001d50 <growproc+0x22>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bff9                	j	80001d54 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	00b90633          	add	a2,s2,a1
    80001d7c:	6d28                	ld	a0,88(a0)
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	64a080e7          	jalr	1610(ra) # 800013c8 <uvmdealloc>
    80001d86:	85aa                	mv	a1,a0
    80001d88:	b7e1                	j	80001d50 <growproc+0x22>

0000000080001d8a <fork>:
{
    80001d8a:	7139                	addi	sp,sp,-64
    80001d8c:	fc06                	sd	ra,56(sp)
    80001d8e:	f822                	sd	s0,48(sp)
    80001d90:	f426                	sd	s1,40(sp)
    80001d92:	f04a                	sd	s2,32(sp)
    80001d94:	ec4e                	sd	s3,24(sp)
    80001d96:	e852                	sd	s4,16(sp)
    80001d98:	e456                	sd	s5,8(sp)
    80001d9a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	c10080e7          	jalr	-1008(ra) # 800019ac <myproc>
    80001da4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	e10080e7          	jalr	-496(ra) # 80001bb6 <allocproc>
    80001dae:	10050c63          	beqz	a0,80001ec6 <fork+0x13c>
    80001db2:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db4:	048ab603          	ld	a2,72(s5)
    80001db8:	6d2c                	ld	a1,88(a0)
    80001dba:	058ab503          	ld	a0,88(s5)
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	7a6080e7          	jalr	1958(ra) # 80001564 <uvmcopy>
    80001dc6:	04054863          	bltz	a0,80001e16 <fork+0x8c>
  np->sz = p->sz;
    80001dca:	048ab783          	ld	a5,72(s5)
    80001dce:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd2:	060ab683          	ld	a3,96(s5)
    80001dd6:	87b6                	mv	a5,a3
    80001dd8:	060a3703          	ld	a4,96(s4)
    80001ddc:	12068693          	addi	a3,a3,288
    80001de0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de4:	6788                	ld	a0,8(a5)
    80001de6:	6b8c                	ld	a1,16(a5)
    80001de8:	6f90                	ld	a2,24(a5)
    80001dea:	01073023          	sd	a6,0(a4)
    80001dee:	e708                	sd	a0,8(a4)
    80001df0:	eb0c                	sd	a1,16(a4)
    80001df2:	ef10                	sd	a2,24(a4)
    80001df4:	02078793          	addi	a5,a5,32
    80001df8:	02070713          	addi	a4,a4,32
    80001dfc:	fed792e3          	bne	a5,a3,80001de0 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e00:	060a3783          	ld	a5,96(s4)
    80001e04:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e08:	0f0a8493          	addi	s1,s5,240
    80001e0c:	0f0a0913          	addi	s2,s4,240
    80001e10:	170a8993          	addi	s3,s5,368
    80001e14:	a00d                	j	80001e36 <fork+0xac>
    freeproc(np);
    80001e16:	8552                	mv	a0,s4
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	d46080e7          	jalr	-698(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e20:	8552                	mv	a0,s4
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e68080e7          	jalr	-408(ra) # 80000c8a <release>
    return -1;
    80001e2a:	597d                	li	s2,-1
    80001e2c:	a059                	j	80001eb2 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e2e:	04a1                	addi	s1,s1,8
    80001e30:	0921                	addi	s2,s2,8
    80001e32:	01348b63          	beq	s1,s3,80001e48 <fork+0xbe>
    if (p->ofile[i])
    80001e36:	6088                	ld	a0,0(s1)
    80001e38:	d97d                	beqz	a0,80001e2e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3a:	00003097          	auipc	ra,0x3
    80001e3e:	9c8080e7          	jalr	-1592(ra) # 80004802 <filedup>
    80001e42:	00a93023          	sd	a0,0(s2)
    80001e46:	b7e5                	j	80001e2e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e48:	170ab503          	ld	a0,368(s5)
    80001e4c:	00002097          	auipc	ra,0x2
    80001e50:	b3c080e7          	jalr	-1220(ra) # 80003988 <idup>
    80001e54:	16aa3823          	sd	a0,368(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e58:	4641                	li	a2,16
    80001e5a:	178a8593          	addi	a1,s5,376
    80001e5e:	178a0513          	addi	a0,s4,376
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	fba080e7          	jalr	-70(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e6a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e6e:	8552                	mv	a0,s4
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	e1a080e7          	jalr	-486(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e78:	0000f497          	auipc	s1,0xf
    80001e7c:	cf048493          	addi	s1,s1,-784 # 80010b68 <wait_lock>
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	d54080e7          	jalr	-684(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e8a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e98:	8552                	mv	a0,s4
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ea2:	478d                	li	a5,3
    80001ea4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea8:	8552                	mv	a0,s4
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	de0080e7          	jalr	-544(ra) # 80000c8a <release>
}
    80001eb2:	854a                	mv	a0,s2
    80001eb4:	70e2                	ld	ra,56(sp)
    80001eb6:	7442                	ld	s0,48(sp)
    80001eb8:	74a2                	ld	s1,40(sp)
    80001eba:	7902                	ld	s2,32(sp)
    80001ebc:	69e2                	ld	s3,24(sp)
    80001ebe:	6a42                	ld	s4,16(sp)
    80001ec0:	6aa2                	ld	s5,8(sp)
    80001ec2:	6121                	addi	sp,sp,64
    80001ec4:	8082                	ret
    return -1;
    80001ec6:	597d                	li	s2,-1
    80001ec8:	b7ed                	j	80001eb2 <fork+0x128>

0000000080001eca <scheduler>:
{
    80001eca:	7139                	addi	sp,sp,-64
    80001ecc:	fc06                	sd	ra,56(sp)
    80001ece:	f822                	sd	s0,48(sp)
    80001ed0:	f426                	sd	s1,40(sp)
    80001ed2:	f04a                	sd	s2,32(sp)
    80001ed4:	ec4e                	sd	s3,24(sp)
    80001ed6:	e852                	sd	s4,16(sp)
    80001ed8:	e456                	sd	s5,8(sp)
    80001eda:	e05a                	sd	s6,0(sp)
    80001edc:	0080                	addi	s0,sp,64
    80001ede:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee2:	00779a93          	slli	s5,a5,0x7
    80001ee6:	0000f717          	auipc	a4,0xf
    80001eea:	c6a70713          	addi	a4,a4,-918 # 80010b50 <pid_lock>
    80001eee:	9756                	add	a4,a4,s5
    80001ef0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef4:	0000f717          	auipc	a4,0xf
    80001ef8:	c9470713          	addi	a4,a4,-876 # 80010b88 <cpus+0x8>
    80001efc:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001efe:	498d                	li	s3,3
        p->state = RUNNING;
    80001f00:	4b11                	li	s6,4
        c->proc = p;
    80001f02:	079e                	slli	a5,a5,0x7
    80001f04:	0000fa17          	auipc	s4,0xf
    80001f08:	c4ca0a13          	addi	s4,s4,-948 # 80010b50 <pid_lock>
    80001f0c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f0e:	00015917          	auipc	s2,0x15
    80001f12:	67290913          	addi	s2,s2,1650 # 80017580 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f1e:	10079073          	csrw	sstatus,a5
    80001f22:	0000f497          	auipc	s1,0xf
    80001f26:	05e48493          	addi	s1,s1,94 # 80010f80 <proc>
    80001f2a:	a811                	j	80001f3e <scheduler+0x74>
      release(&p->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d5c080e7          	jalr	-676(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f36:	19848493          	addi	s1,s1,408
    80001f3a:	fd248ee3          	beq	s1,s2,80001f16 <scheduler+0x4c>
      acquire(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	c96080e7          	jalr	-874(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f48:	4c9c                	lw	a5,24(s1)
    80001f4a:	ff3791e3          	bne	a5,s3,80001f2c <scheduler+0x62>
        p->state = RUNNING;
    80001f4e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f52:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f56:	08048593          	addi	a1,s1,128
    80001f5a:	8556                	mv	a0,s5
    80001f5c:	00001097          	auipc	ra,0x1
    80001f60:	838080e7          	jalr	-1992(ra) # 80002794 <swtch>
        c->proc = 0;
    80001f64:	020a3823          	sd	zero,48(s4)
    80001f68:	b7d1                	j	80001f2c <scheduler+0x62>

0000000080001f6a <sched>:
{
    80001f6a:	7179                	addi	sp,sp,-48
    80001f6c:	f406                	sd	ra,40(sp)
    80001f6e:	f022                	sd	s0,32(sp)
    80001f70:	ec26                	sd	s1,24(sp)
    80001f72:	e84a                	sd	s2,16(sp)
    80001f74:	e44e                	sd	s3,8(sp)
    80001f76:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	a34080e7          	jalr	-1484(ra) # 800019ac <myproc>
    80001f80:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	bda080e7          	jalr	-1062(ra) # 80000b5c <holding>
    80001f8a:	c93d                	beqz	a0,80002000 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	079e                	slli	a5,a5,0x7
    80001f92:	0000f717          	auipc	a4,0xf
    80001f96:	bbe70713          	addi	a4,a4,-1090 # 80010b50 <pid_lock>
    80001f9a:	97ba                	add	a5,a5,a4
    80001f9c:	0a87a703          	lw	a4,168(a5)
    80001fa0:	4785                	li	a5,1
    80001fa2:	06f71763          	bne	a4,a5,80002010 <sched+0xa6>
  if (p->state == RUNNING)
    80001fa6:	4c98                	lw	a4,24(s1)
    80001fa8:	4791                	li	a5,4
    80001faa:	06f70b63          	beq	a4,a5,80002020 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb2:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fb4:	efb5                	bnez	a5,80002030 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb8:	0000f917          	auipc	s2,0xf
    80001fbc:	b9890913          	addi	s2,s2,-1128 # 80010b50 <pid_lock>
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0ac7a983          	lw	s3,172(a5)
    80001fca:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fcc:	2781                	sext.w	a5,a5
    80001fce:	079e                	slli	a5,a5,0x7
    80001fd0:	0000f597          	auipc	a1,0xf
    80001fd4:	bb858593          	addi	a1,a1,-1096 # 80010b88 <cpus+0x8>
    80001fd8:	95be                	add	a1,a1,a5
    80001fda:	08048513          	addi	a0,s1,128
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	7b6080e7          	jalr	1974(ra) # 80002794 <swtch>
    80001fe6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	97ca                	add	a5,a5,s2
    80001fee:	0b37a623          	sw	s3,172(a5)
}
    80001ff2:	70a2                	ld	ra,40(sp)
    80001ff4:	7402                	ld	s0,32(sp)
    80001ff6:	64e2                	ld	s1,24(sp)
    80001ff8:	6942                	ld	s2,16(sp)
    80001ffa:	69a2                	ld	s3,8(sp)
    80001ffc:	6145                	addi	sp,sp,48
    80001ffe:	8082                	ret
    panic("sched p->lock");
    80002000:	00006517          	auipc	a0,0x6
    80002004:	21850513          	addi	a0,a0,536 # 80008218 <digits+0x1d8>
    80002008:	ffffe097          	auipc	ra,0xffffe
    8000200c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    panic("sched locks");
    80002010:	00006517          	auipc	a0,0x6
    80002014:	21850513          	addi	a0,a0,536 # 80008228 <digits+0x1e8>
    80002018:	ffffe097          	auipc	ra,0xffffe
    8000201c:	526080e7          	jalr	1318(ra) # 8000053e <panic>
    panic("sched running");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	21850513          	addi	a0,a0,536 # 80008238 <digits+0x1f8>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	516080e7          	jalr	1302(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	21850513          	addi	a0,a0,536 # 80008248 <digits+0x208>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	506080e7          	jalr	1286(ra) # 8000053e <panic>

0000000080002040 <yield>:
{
    80002040:	1101                	addi	sp,sp,-32
    80002042:	ec06                	sd	ra,24(sp)
    80002044:	e822                	sd	s0,16(sp)
    80002046:	e426                	sd	s1,8(sp)
    80002048:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	962080e7          	jalr	-1694(ra) # 800019ac <myproc>
    80002052:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	b82080e7          	jalr	-1150(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000205c:	478d                	li	a5,3
    8000205e:	cc9c                	sw	a5,24(s1)
  sched();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	f0a080e7          	jalr	-246(ra) # 80001f6a <sched>
  release(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c20080e7          	jalr	-992(ra) # 80000c8a <release>
}
    80002072:	60e2                	ld	ra,24(sp)
    80002074:	6442                	ld	s0,16(sp)
    80002076:	64a2                	ld	s1,8(sp)
    80002078:	6105                	addi	sp,sp,32
    8000207a:	8082                	ret

000000008000207c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000207c:	7179                	addi	sp,sp,-48
    8000207e:	f406                	sd	ra,40(sp)
    80002080:	f022                	sd	s0,32(sp)
    80002082:	ec26                	sd	s1,24(sp)
    80002084:	e84a                	sd	s2,16(sp)
    80002086:	e44e                	sd	s3,8(sp)
    80002088:	1800                	addi	s0,sp,48
    8000208a:	89aa                	mv	s3,a0
    8000208c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	91e080e7          	jalr	-1762(ra) # 800019ac <myproc>
    80002096:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	b3e080e7          	jalr	-1218(ra) # 80000bd6 <acquire>
  release(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	be8080e7          	jalr	-1048(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020aa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ae:	4789                	li	a5,2
    800020b0:	cc9c                	sw	a5,24(s1)

  sched();
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	eb8080e7          	jalr	-328(ra) # 80001f6a <sched>

  // Tidy up.
  p->chan = 0;
    800020ba:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020be:	8526                	mv	a0,s1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	bca080e7          	jalr	-1078(ra) # 80000c8a <release>
  acquire(lk);
    800020c8:	854a                	mv	a0,s2
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b0c080e7          	jalr	-1268(ra) # 80000bd6 <acquire>
}
    800020d2:	70a2                	ld	ra,40(sp)
    800020d4:	7402                	ld	s0,32(sp)
    800020d6:	64e2                	ld	s1,24(sp)
    800020d8:	6942                	ld	s2,16(sp)
    800020da:	69a2                	ld	s3,8(sp)
    800020dc:	6145                	addi	sp,sp,48
    800020de:	8082                	ret

00000000800020e0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020e0:	7139                	addi	sp,sp,-64
    800020e2:	fc06                	sd	ra,56(sp)
    800020e4:	f822                	sd	s0,48(sp)
    800020e6:	f426                	sd	s1,40(sp)
    800020e8:	f04a                	sd	s2,32(sp)
    800020ea:	ec4e                	sd	s3,24(sp)
    800020ec:	e852                	sd	s4,16(sp)
    800020ee:	e456                	sd	s5,8(sp)
    800020f0:	0080                	addi	s0,sp,64
    800020f2:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020f4:	0000f497          	auipc	s1,0xf
    800020f8:	e8c48493          	addi	s1,s1,-372 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020fc:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020fe:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002100:	00015917          	auipc	s2,0x15
    80002104:	48090913          	addi	s2,s2,1152 # 80017580 <tickslock>
    80002108:	a811                	j	8000211c <wakeup+0x3c>
      }
      release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b7e080e7          	jalr	-1154(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002114:	19848493          	addi	s1,s1,408
    80002118:	03248663          	beq	s1,s2,80002144 <wakeup+0x64>
    if (p != myproc())
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	890080e7          	jalr	-1904(ra) # 800019ac <myproc>
    80002124:	fea488e3          	beq	s1,a0,80002114 <wakeup+0x34>
      acquire(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aac080e7          	jalr	-1364(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002132:	4c9c                	lw	a5,24(s1)
    80002134:	fd379be3          	bne	a5,s3,8000210a <wakeup+0x2a>
    80002138:	709c                	ld	a5,32(s1)
    8000213a:	fd4798e3          	bne	a5,s4,8000210a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000213e:	0154ac23          	sw	s5,24(s1)
    80002142:	b7e1                	j	8000210a <wakeup+0x2a>
    }
  }
}
    80002144:	70e2                	ld	ra,56(sp)
    80002146:	7442                	ld	s0,48(sp)
    80002148:	74a2                	ld	s1,40(sp)
    8000214a:	7902                	ld	s2,32(sp)
    8000214c:	69e2                	ld	s3,24(sp)
    8000214e:	6a42                	ld	s4,16(sp)
    80002150:	6aa2                	ld	s5,8(sp)
    80002152:	6121                	addi	sp,sp,64
    80002154:	8082                	ret

0000000080002156 <reparent>:
{
    80002156:	7179                	addi	sp,sp,-48
    80002158:	f406                	sd	ra,40(sp)
    8000215a:	f022                	sd	s0,32(sp)
    8000215c:	ec26                	sd	s1,24(sp)
    8000215e:	e84a                	sd	s2,16(sp)
    80002160:	e44e                	sd	s3,8(sp)
    80002162:	e052                	sd	s4,0(sp)
    80002164:	1800                	addi	s0,sp,48
    80002166:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002168:	0000f497          	auipc	s1,0xf
    8000216c:	e1848493          	addi	s1,s1,-488 # 80010f80 <proc>
      pp->parent = initproc;
    80002170:	00006a17          	auipc	s4,0x6
    80002174:	768a0a13          	addi	s4,s4,1896 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002178:	00015997          	auipc	s3,0x15
    8000217c:	40898993          	addi	s3,s3,1032 # 80017580 <tickslock>
    80002180:	a029                	j	8000218a <reparent+0x34>
    80002182:	19848493          	addi	s1,s1,408
    80002186:	01348d63          	beq	s1,s3,800021a0 <reparent+0x4a>
    if (pp->parent == p)
    8000218a:	7c9c                	ld	a5,56(s1)
    8000218c:	ff279be3          	bne	a5,s2,80002182 <reparent+0x2c>
      pp->parent = initproc;
    80002190:	000a3503          	ld	a0,0(s4)
    80002194:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	f4a080e7          	jalr	-182(ra) # 800020e0 <wakeup>
    8000219e:	b7d5                	j	80002182 <reparent+0x2c>
}
    800021a0:	70a2                	ld	ra,40(sp)
    800021a2:	7402                	ld	s0,32(sp)
    800021a4:	64e2                	ld	s1,24(sp)
    800021a6:	6942                	ld	s2,16(sp)
    800021a8:	69a2                	ld	s3,8(sp)
    800021aa:	6a02                	ld	s4,0(sp)
    800021ac:	6145                	addi	sp,sp,48
    800021ae:	8082                	ret

00000000800021b0 <exit>:
{
    800021b0:	7179                	addi	sp,sp,-48
    800021b2:	f406                	sd	ra,40(sp)
    800021b4:	f022                	sd	s0,32(sp)
    800021b6:	ec26                	sd	s1,24(sp)
    800021b8:	e84a                	sd	s2,16(sp)
    800021ba:	e44e                	sd	s3,8(sp)
    800021bc:	e052                	sd	s4,0(sp)
    800021be:	1800                	addi	s0,sp,48
    800021c0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	7ea080e7          	jalr	2026(ra) # 800019ac <myproc>
    800021ca:	89aa                	mv	s3,a0
  if (p == initproc)
    800021cc:	00006797          	auipc	a5,0x6
    800021d0:	70c7b783          	ld	a5,1804(a5) # 800088d8 <initproc>
    800021d4:	0f050493          	addi	s1,a0,240
    800021d8:	17050913          	addi	s2,a0,368
    800021dc:	02a79363          	bne	a5,a0,80002202 <exit+0x52>
    panic("init exiting");
    800021e0:	00006517          	auipc	a0,0x6
    800021e4:	08050513          	addi	a0,a0,128 # 80008260 <digits+0x220>
    800021e8:	ffffe097          	auipc	ra,0xffffe
    800021ec:	356080e7          	jalr	854(ra) # 8000053e <panic>
      fileclose(f);
    800021f0:	00002097          	auipc	ra,0x2
    800021f4:	664080e7          	jalr	1636(ra) # 80004854 <fileclose>
      p->ofile[fd] = 0;
    800021f8:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021fc:	04a1                	addi	s1,s1,8
    800021fe:	01248563          	beq	s1,s2,80002208 <exit+0x58>
    if (p->ofile[fd])
    80002202:	6088                	ld	a0,0(s1)
    80002204:	f575                	bnez	a0,800021f0 <exit+0x40>
    80002206:	bfdd                	j	800021fc <exit+0x4c>
  begin_op();
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	180080e7          	jalr	384(ra) # 80004388 <begin_op>
  iput(p->cwd);
    80002210:	1709b503          	ld	a0,368(s3)
    80002214:	00002097          	auipc	ra,0x2
    80002218:	96c080e7          	jalr	-1684(ra) # 80003b80 <iput>
  end_op();
    8000221c:	00002097          	auipc	ra,0x2
    80002220:	1ec080e7          	jalr	492(ra) # 80004408 <end_op>
  p->cwd = 0;
    80002224:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002228:	0000f497          	auipc	s1,0xf
    8000222c:	94048493          	addi	s1,s1,-1728 # 80010b68 <wait_lock>
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9a4080e7          	jalr	-1628(ra) # 80000bd6 <acquire>
  reparent(p);
    8000223a:	854e                	mv	a0,s3
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	f1a080e7          	jalr	-230(ra) # 80002156 <reparent>
  wakeup(p->parent);
    80002244:	0389b503          	ld	a0,56(s3)
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	e98080e7          	jalr	-360(ra) # 800020e0 <wakeup>
  acquire(&p->lock);
    80002250:	854e                	mv	a0,s3
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	984080e7          	jalr	-1660(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000225a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000225e:	4795                	li	a5,5
    80002260:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002264:	00006797          	auipc	a5,0x6
    80002268:	67c7a783          	lw	a5,1660(a5) # 800088e0 <ticks>
    8000226c:	18f9a823          	sw	a5,400(s3)
  release(&wait_lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	cf0080e7          	jalr	-784(ra) # 80001f6a <sched>
  panic("zombie exit");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fee50513          	addi	a0,a0,-18 # 80008270 <digits+0x230>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>

0000000080002292 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002292:	7179                	addi	sp,sp,-48
    80002294:	f406                	sd	ra,40(sp)
    80002296:	f022                	sd	s0,32(sp)
    80002298:	ec26                	sd	s1,24(sp)
    8000229a:	e84a                	sd	s2,16(sp)
    8000229c:	e44e                	sd	s3,8(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022a2:	0000f497          	auipc	s1,0xf
    800022a6:	cde48493          	addi	s1,s1,-802 # 80010f80 <proc>
    800022aa:	00015997          	auipc	s3,0x15
    800022ae:	2d698993          	addi	s3,s3,726 # 80017580 <tickslock>
  {
    acquire(&p->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	922080e7          	jalr	-1758(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022bc:	589c                	lw	a5,48(s1)
    800022be:	01278d63          	beq	a5,s2,800022d8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	9c6080e7          	jalr	-1594(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022cc:	19848493          	addi	s1,s1,408
    800022d0:	ff3491e3          	bne	s1,s3,800022b2 <kill+0x20>
  }
  return -1;
    800022d4:	557d                	li	a0,-1
    800022d6:	a829                	j	800022f0 <kill+0x5e>
      p->killed = 1;
    800022d8:	4785                	li	a5,1
    800022da:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022dc:	4c98                	lw	a4,24(s1)
    800022de:	4789                	li	a5,2
    800022e0:	00f70f63          	beq	a4,a5,800022fe <kill+0x6c>
      release(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9a4080e7          	jalr	-1628(ra) # 80000c8a <release>
      return 0;
    800022ee:	4501                	li	a0,0
}
    800022f0:	70a2                	ld	ra,40(sp)
    800022f2:	7402                	ld	s0,32(sp)
    800022f4:	64e2                	ld	s1,24(sp)
    800022f6:	6942                	ld	s2,16(sp)
    800022f8:	69a2                	ld	s3,8(sp)
    800022fa:	6145                	addi	sp,sp,48
    800022fc:	8082                	ret
        p->state = RUNNABLE;
    800022fe:	478d                	li	a5,3
    80002300:	cc9c                	sw	a5,24(s1)
    80002302:	b7cd                	j	800022e4 <kill+0x52>

0000000080002304 <setkilled>:

void setkilled(struct proc *p)
{
    80002304:	1101                	addi	sp,sp,-32
    80002306:	ec06                	sd	ra,24(sp)
    80002308:	e822                	sd	s0,16(sp)
    8000230a:	e426                	sd	s1,8(sp)
    8000230c:	1000                	addi	s0,sp,32
    8000230e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	8c6080e7          	jalr	-1850(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002318:	4785                	li	a5,1
    8000231a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	96c080e7          	jalr	-1684(ra) # 80000c8a <release>
}
    80002326:	60e2                	ld	ra,24(sp)
    80002328:	6442                	ld	s0,16(sp)
    8000232a:	64a2                	ld	s1,8(sp)
    8000232c:	6105                	addi	sp,sp,32
    8000232e:	8082                	ret

0000000080002330 <killed>:

int killed(struct proc *p)
{
    80002330:	1101                	addi	sp,sp,-32
    80002332:	ec06                	sd	ra,24(sp)
    80002334:	e822                	sd	s0,16(sp)
    80002336:	e426                	sd	s1,8(sp)
    80002338:	e04a                	sd	s2,0(sp)
    8000233a:	1000                	addi	s0,sp,32
    8000233c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	898080e7          	jalr	-1896(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002346:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	93e080e7          	jalr	-1730(ra) # 80000c8a <release>
  return k;
}
    80002354:	854a                	mv	a0,s2
    80002356:	60e2                	ld	ra,24(sp)
    80002358:	6442                	ld	s0,16(sp)
    8000235a:	64a2                	ld	s1,8(sp)
    8000235c:	6902                	ld	s2,0(sp)
    8000235e:	6105                	addi	sp,sp,32
    80002360:	8082                	ret

0000000080002362 <wait>:
{
    80002362:	715d                	addi	sp,sp,-80
    80002364:	e486                	sd	ra,72(sp)
    80002366:	e0a2                	sd	s0,64(sp)
    80002368:	fc26                	sd	s1,56(sp)
    8000236a:	f84a                	sd	s2,48(sp)
    8000236c:	f44e                	sd	s3,40(sp)
    8000236e:	f052                	sd	s4,32(sp)
    80002370:	ec56                	sd	s5,24(sp)
    80002372:	e85a                	sd	s6,16(sp)
    80002374:	e45e                	sd	s7,8(sp)
    80002376:	e062                	sd	s8,0(sp)
    80002378:	0880                	addi	s0,sp,80
    8000237a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	630080e7          	jalr	1584(ra) # 800019ac <myproc>
    80002384:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002386:	0000e517          	auipc	a0,0xe
    8000238a:	7e250513          	addi	a0,a0,2018 # 80010b68 <wait_lock>
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002396:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002398:	4a15                	li	s4,5
        havekids = 1;
    8000239a:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239c:	00015997          	auipc	s3,0x15
    800023a0:	1e498993          	addi	s3,s3,484 # 80017580 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023a4:	0000ec17          	auipc	s8,0xe
    800023a8:	7c4c0c13          	addi	s8,s8,1988 # 80010b68 <wait_lock>
    havekids = 0;
    800023ac:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023ae:	0000f497          	auipc	s1,0xf
    800023b2:	bd248493          	addi	s1,s1,-1070 # 80010f80 <proc>
    800023b6:	a0bd                	j	80002424 <wait+0xc2>
          pid = pp->pid;
    800023b8:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023bc:	000b0e63          	beqz	s6,800023d8 <wait+0x76>
    800023c0:	4691                	li	a3,4
    800023c2:	02c48613          	addi	a2,s1,44
    800023c6:	85da                	mv	a1,s6
    800023c8:	05893503          	ld	a0,88(s2)
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	29c080e7          	jalr	668(ra) # 80001668 <copyout>
    800023d4:	02054563          	bltz	a0,800023fe <wait+0x9c>
          freeproc(pp);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	784080e7          	jalr	1924(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
          release(&wait_lock);
    800023ec:	0000e517          	auipc	a0,0xe
    800023f0:	77c50513          	addi	a0,a0,1916 # 80010b68 <wait_lock>
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	896080e7          	jalr	-1898(ra) # 80000c8a <release>
          return pid;
    800023fc:	a0b5                	j	80002468 <wait+0x106>
            release(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	88a080e7          	jalr	-1910(ra) # 80000c8a <release>
            release(&wait_lock);
    80002408:	0000e517          	auipc	a0,0xe
    8000240c:	76050513          	addi	a0,a0,1888 # 80010b68 <wait_lock>
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	87a080e7          	jalr	-1926(ra) # 80000c8a <release>
            return -1;
    80002418:	59fd                	li	s3,-1
    8000241a:	a0b9                	j	80002468 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241c:	19848493          	addi	s1,s1,408
    80002420:	03348463          	beq	s1,s3,80002448 <wait+0xe6>
      if (pp->parent == p)
    80002424:	7c9c                	ld	a5,56(s1)
    80002426:	ff279be3          	bne	a5,s2,8000241c <wait+0xba>
        acquire(&pp->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	7aa080e7          	jalr	1962(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002434:	4c9c                	lw	a5,24(s1)
    80002436:	f94781e3          	beq	a5,s4,800023b8 <wait+0x56>
        release(&pp->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
        havekids = 1;
    80002444:	8756                	mv	a4,s5
    80002446:	bfd9                	j	8000241c <wait+0xba>
    if (!havekids || killed(p))
    80002448:	c719                	beqz	a4,80002456 <wait+0xf4>
    8000244a:	854a                	mv	a0,s2
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	ee4080e7          	jalr	-284(ra) # 80002330 <killed>
    80002454:	c51d                	beqz	a0,80002482 <wait+0x120>
      release(&wait_lock);
    80002456:	0000e517          	auipc	a0,0xe
    8000245a:	71250513          	addi	a0,a0,1810 # 80010b68 <wait_lock>
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
      return -1;
    80002466:	59fd                	li	s3,-1
}
    80002468:	854e                	mv	a0,s3
    8000246a:	60a6                	ld	ra,72(sp)
    8000246c:	6406                	ld	s0,64(sp)
    8000246e:	74e2                	ld	s1,56(sp)
    80002470:	7942                	ld	s2,48(sp)
    80002472:	79a2                	ld	s3,40(sp)
    80002474:	7a02                	ld	s4,32(sp)
    80002476:	6ae2                	ld	s5,24(sp)
    80002478:	6b42                	ld	s6,16(sp)
    8000247a:	6ba2                	ld	s7,8(sp)
    8000247c:	6c02                	ld	s8,0(sp)
    8000247e:	6161                	addi	sp,sp,80
    80002480:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002482:	85e2                	mv	a1,s8
    80002484:	854a                	mv	a0,s2
    80002486:	00000097          	auipc	ra,0x0
    8000248a:	bf6080e7          	jalr	-1034(ra) # 8000207c <sleep>
    havekids = 0;
    8000248e:	bf39                	j	800023ac <wait+0x4a>

0000000080002490 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	84aa                	mv	s1,a0
    800024a2:	892e                	mv	s2,a1
    800024a4:	89b2                	mv	s3,a2
    800024a6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	504080e7          	jalr	1284(ra) # 800019ac <myproc>
  if (user_dst)
    800024b0:	c08d                	beqz	s1,800024d2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024b2:	86d2                	mv	a3,s4
    800024b4:	864e                	mv	a2,s3
    800024b6:	85ca                	mv	a1,s2
    800024b8:	6d28                	ld	a0,88(a0)
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	1ae080e7          	jalr	430(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c2:	70a2                	ld	ra,40(sp)
    800024c4:	7402                	ld	s0,32(sp)
    800024c6:	64e2                	ld	s1,24(sp)
    800024c8:	6942                	ld	s2,16(sp)
    800024ca:	69a2                	ld	s3,8(sp)
    800024cc:	6a02                	ld	s4,0(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret
    memmove((char *)dst, src, len);
    800024d2:	000a061b          	sext.w	a2,s4
    800024d6:	85ce                	mv	a1,s3
    800024d8:	854a                	mv	a0,s2
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	854080e7          	jalr	-1964(ra) # 80000d2e <memmove>
    return 0;
    800024e2:	8526                	mv	a0,s1
    800024e4:	bff9                	j	800024c2 <either_copyout+0x32>

00000000800024e6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e6:	7179                	addi	sp,sp,-48
    800024e8:	f406                	sd	ra,40(sp)
    800024ea:	f022                	sd	s0,32(sp)
    800024ec:	ec26                	sd	s1,24(sp)
    800024ee:	e84a                	sd	s2,16(sp)
    800024f0:	e44e                	sd	s3,8(sp)
    800024f2:	e052                	sd	s4,0(sp)
    800024f4:	1800                	addi	s0,sp,48
    800024f6:	892a                	mv	s2,a0
    800024f8:	84ae                	mv	s1,a1
    800024fa:	89b2                	mv	s3,a2
    800024fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	4ae080e7          	jalr	1198(ra) # 800019ac <myproc>
  if (user_src)
    80002506:	c08d                	beqz	s1,80002528 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002508:	86d2                	mv	a3,s4
    8000250a:	864e                	mv	a2,s3
    8000250c:	85ca                	mv	a1,s2
    8000250e:	6d28                	ld	a0,88(a0)
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	1e4080e7          	jalr	484(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6a02                	ld	s4,0(sp)
    80002524:	6145                	addi	sp,sp,48
    80002526:	8082                	ret
    memmove(dst, (char *)src, len);
    80002528:	000a061b          	sext.w	a2,s4
    8000252c:	85ce                	mv	a1,s3
    8000252e:	854a                	mv	a0,s2
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	7fe080e7          	jalr	2046(ra) # 80000d2e <memmove>
    return 0;
    80002538:	8526                	mv	a0,s1
    8000253a:	bff9                	j	80002518 <either_copyin+0x32>

000000008000253c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000253c:	715d                	addi	sp,sp,-80
    8000253e:	e486                	sd	ra,72(sp)
    80002540:	e0a2                	sd	s0,64(sp)
    80002542:	fc26                	sd	s1,56(sp)
    80002544:	f84a                	sd	s2,48(sp)
    80002546:	f44e                	sd	s3,40(sp)
    80002548:	f052                	sd	s4,32(sp)
    8000254a:	ec56                	sd	s5,24(sp)
    8000254c:	e85a                	sd	s6,16(sp)
    8000254e:	e45e                	sd	s7,8(sp)
    80002550:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002552:	00006517          	auipc	a0,0x6
    80002556:	b7650513          	addi	a0,a0,-1162 # 800080c8 <digits+0x88>
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	b9648493          	addi	s1,s1,-1130 # 800110f8 <proc+0x178>
    8000256a:	00015917          	auipc	s2,0x15
    8000256e:	18e90913          	addi	s2,s2,398 # 800176f8 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002572:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002574:	00006997          	auipc	s3,0x6
    80002578:	d0c98993          	addi	s3,s3,-756 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000257c:	00006a97          	auipc	s5,0x6
    80002580:	d0ca8a93          	addi	s5,s5,-756 # 80008288 <digits+0x248>
    printf("\n");
    80002584:	00006a17          	auipc	s4,0x6
    80002588:	b44a0a13          	addi	s4,s4,-1212 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	00006b97          	auipc	s7,0x6
    80002590:	d3cb8b93          	addi	s7,s7,-708 # 800082c8 <states.0>
    80002594:	a00d                	j	800025b6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002596:	eb86a583          	lw	a1,-328(a3)
    8000259a:	8556                	mv	a0,s5
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fec080e7          	jalr	-20(ra) # 80000588 <printf>
    printf("\n");
    800025a4:	8552                	mv	a0,s4
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	fe2080e7          	jalr	-30(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ae:	19848493          	addi	s1,s1,408
    800025b2:	03248163          	beq	s1,s2,800025d4 <procdump+0x98>
    if (p->state == UNUSED)
    800025b6:	86a6                	mv	a3,s1
    800025b8:	ea04a783          	lw	a5,-352(s1)
    800025bc:	dbed                	beqz	a5,800025ae <procdump+0x72>
      state = "???";
    800025be:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c0:	fcfb6be3          	bltu	s6,a5,80002596 <procdump+0x5a>
    800025c4:	1782                	slli	a5,a5,0x20
    800025c6:	9381                	srli	a5,a5,0x20
    800025c8:	078e                	slli	a5,a5,0x3
    800025ca:	97de                	add	a5,a5,s7
    800025cc:	6390                	ld	a2,0(a5)
    800025ce:	f661                	bnez	a2,80002596 <procdump+0x5a>
      state = "???";
    800025d0:	864e                	mv	a2,s3
    800025d2:	b7d1                	j	80002596 <procdump+0x5a>
  }
}
    800025d4:	60a6                	ld	ra,72(sp)
    800025d6:	6406                	ld	s0,64(sp)
    800025d8:	74e2                	ld	s1,56(sp)
    800025da:	7942                	ld	s2,48(sp)
    800025dc:	79a2                	ld	s3,40(sp)
    800025de:	7a02                	ld	s4,32(sp)
    800025e0:	6ae2                	ld	s5,24(sp)
    800025e2:	6b42                	ld	s6,16(sp)
    800025e4:	6ba2                	ld	s7,8(sp)
    800025e6:	6161                	addi	sp,sp,80
    800025e8:	8082                	ret

00000000800025ea <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025ea:	711d                	addi	sp,sp,-96
    800025ec:	ec86                	sd	ra,88(sp)
    800025ee:	e8a2                	sd	s0,80(sp)
    800025f0:	e4a6                	sd	s1,72(sp)
    800025f2:	e0ca                	sd	s2,64(sp)
    800025f4:	fc4e                	sd	s3,56(sp)
    800025f6:	f852                	sd	s4,48(sp)
    800025f8:	f456                	sd	s5,40(sp)
    800025fa:	f05a                	sd	s6,32(sp)
    800025fc:	ec5e                	sd	s7,24(sp)
    800025fe:	e862                	sd	s8,16(sp)
    80002600:	e466                	sd	s9,8(sp)
    80002602:	e06a                	sd	s10,0(sp)
    80002604:	1080                	addi	s0,sp,96
    80002606:	8b2a                	mv	s6,a0
    80002608:	8bae                	mv	s7,a1
    8000260a:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	3a0080e7          	jalr	928(ra) # 800019ac <myproc>
    80002614:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002616:	0000e517          	auipc	a0,0xe
    8000261a:	55250513          	addi	a0,a0,1362 # 80010b68 <wait_lock>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	5b8080e7          	jalr	1464(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002626:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002628:	4a15                	li	s4,5
        havekids = 1;
    8000262a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000262c:	00015997          	auipc	s3,0x15
    80002630:	f5498993          	addi	s3,s3,-172 # 80017580 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002634:	0000ed17          	auipc	s10,0xe
    80002638:	534d0d13          	addi	s10,s10,1332 # 80010b68 <wait_lock>
    havekids = 0;
    8000263c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000263e:	0000f497          	auipc	s1,0xf
    80002642:	94248493          	addi	s1,s1,-1726 # 80010f80 <proc>
    80002646:	a059                	j	800026cc <waitx+0xe2>
          pid = np->pid;
    80002648:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000264c:	1884a703          	lw	a4,392(s1)
    80002650:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002654:	18c4a783          	lw	a5,396(s1)
    80002658:	9f3d                	addw	a4,a4,a5
    8000265a:	1904a783          	lw	a5,400(s1)
    8000265e:	9f99                	subw	a5,a5,a4
    80002660:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002664:	000b0e63          	beqz	s6,80002680 <waitx+0x96>
    80002668:	4691                	li	a3,4
    8000266a:	02c48613          	addi	a2,s1,44
    8000266e:	85da                	mv	a1,s6
    80002670:	05893503          	ld	a0,88(s2)
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	ff4080e7          	jalr	-12(ra) # 80001668 <copyout>
    8000267c:	02054563          	bltz	a0,800026a6 <waitx+0xbc>
          freeproc(np);
    80002680:	8526                	mv	a0,s1
    80002682:	fffff097          	auipc	ra,0xfffff
    80002686:	4dc080e7          	jalr	1244(ra) # 80001b5e <freeproc>
          release(&np->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	5fe080e7          	jalr	1534(ra) # 80000c8a <release>
          release(&wait_lock);
    80002694:	0000e517          	auipc	a0,0xe
    80002698:	4d450513          	addi	a0,a0,1236 # 80010b68 <wait_lock>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	5ee080e7          	jalr	1518(ra) # 80000c8a <release>
          return pid;
    800026a4:	a09d                	j	8000270a <waitx+0x120>
            release(&np->lock);
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5e2080e7          	jalr	1506(ra) # 80000c8a <release>
            release(&wait_lock);
    800026b0:	0000e517          	auipc	a0,0xe
    800026b4:	4b850513          	addi	a0,a0,1208 # 80010b68 <wait_lock>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5d2080e7          	jalr	1490(ra) # 80000c8a <release>
            return -1;
    800026c0:	59fd                	li	s3,-1
    800026c2:	a0a1                	j	8000270a <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026c4:	19848493          	addi	s1,s1,408
    800026c8:	03348463          	beq	s1,s3,800026f0 <waitx+0x106>
      if (np->parent == p)
    800026cc:	7c9c                	ld	a5,56(s1)
    800026ce:	ff279be3          	bne	a5,s2,800026c4 <waitx+0xda>
        acquire(&np->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	502080e7          	jalr	1282(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026dc:	4c9c                	lw	a5,24(s1)
    800026de:	f74785e3          	beq	a5,s4,80002648 <waitx+0x5e>
        release(&np->lock);
    800026e2:	8526                	mv	a0,s1
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	5a6080e7          	jalr	1446(ra) # 80000c8a <release>
        havekids = 1;
    800026ec:	8756                	mv	a4,s5
    800026ee:	bfd9                	j	800026c4 <waitx+0xda>
    if (!havekids || p->killed)
    800026f0:	c701                	beqz	a4,800026f8 <waitx+0x10e>
    800026f2:	02892783          	lw	a5,40(s2)
    800026f6:	cb8d                	beqz	a5,80002728 <waitx+0x13e>
      release(&wait_lock);
    800026f8:	0000e517          	auipc	a0,0xe
    800026fc:	47050513          	addi	a0,a0,1136 # 80010b68 <wait_lock>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	58a080e7          	jalr	1418(ra) # 80000c8a <release>
      return -1;
    80002708:	59fd                	li	s3,-1
  }
}
    8000270a:	854e                	mv	a0,s3
    8000270c:	60e6                	ld	ra,88(sp)
    8000270e:	6446                	ld	s0,80(sp)
    80002710:	64a6                	ld	s1,72(sp)
    80002712:	6906                	ld	s2,64(sp)
    80002714:	79e2                	ld	s3,56(sp)
    80002716:	7a42                	ld	s4,48(sp)
    80002718:	7aa2                	ld	s5,40(sp)
    8000271a:	7b02                	ld	s6,32(sp)
    8000271c:	6be2                	ld	s7,24(sp)
    8000271e:	6c42                	ld	s8,16(sp)
    80002720:	6ca2                	ld	s9,8(sp)
    80002722:	6d02                	ld	s10,0(sp)
    80002724:	6125                	addi	sp,sp,96
    80002726:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002728:	85ea                	mv	a1,s10
    8000272a:	854a                	mv	a0,s2
    8000272c:	00000097          	auipc	ra,0x0
    80002730:	950080e7          	jalr	-1712(ra) # 8000207c <sleep>
    havekids = 0;
    80002734:	b721                	j	8000263c <waitx+0x52>

0000000080002736 <update_time>:

void update_time()
{
    80002736:	7179                	addi	sp,sp,-48
    80002738:	f406                	sd	ra,40(sp)
    8000273a:	f022                	sd	s0,32(sp)
    8000273c:	ec26                	sd	s1,24(sp)
    8000273e:	e84a                	sd	s2,16(sp)
    80002740:	e44e                	sd	s3,8(sp)
    80002742:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002744:	0000f497          	auipc	s1,0xf
    80002748:	83c48493          	addi	s1,s1,-1988 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000274c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000274e:	00015917          	auipc	s2,0x15
    80002752:	e3290913          	addi	s2,s2,-462 # 80017580 <tickslock>
    80002756:	a811                	j	8000276a <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002762:	19848493          	addi	s1,s1,408
    80002766:	03248063          	beq	s1,s2,80002786 <update_time+0x50>
    acquire(&p->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	46a080e7          	jalr	1130(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002774:	4c9c                	lw	a5,24(s1)
    80002776:	ff3791e3          	bne	a5,s3,80002758 <update_time+0x22>
      p->rtime++;
    8000277a:	1884a783          	lw	a5,392(s1)
    8000277e:	2785                	addiw	a5,a5,1
    80002780:	18f4a423          	sw	a5,392(s1)
    80002784:	bfd1                	j	80002758 <update_time+0x22>
  }
    80002786:	70a2                	ld	ra,40(sp)
    80002788:	7402                	ld	s0,32(sp)
    8000278a:	64e2                	ld	s1,24(sp)
    8000278c:	6942                	ld	s2,16(sp)
    8000278e:	69a2                	ld	s3,8(sp)
    80002790:	6145                	addi	sp,sp,48
    80002792:	8082                	ret

0000000080002794 <swtch>:
    80002794:	00153023          	sd	ra,0(a0)
    80002798:	00253423          	sd	sp,8(a0)
    8000279c:	e900                	sd	s0,16(a0)
    8000279e:	ed04                	sd	s1,24(a0)
    800027a0:	03253023          	sd	s2,32(a0)
    800027a4:	03353423          	sd	s3,40(a0)
    800027a8:	03453823          	sd	s4,48(a0)
    800027ac:	03553c23          	sd	s5,56(a0)
    800027b0:	05653023          	sd	s6,64(a0)
    800027b4:	05753423          	sd	s7,72(a0)
    800027b8:	05853823          	sd	s8,80(a0)
    800027bc:	05953c23          	sd	s9,88(a0)
    800027c0:	07a53023          	sd	s10,96(a0)
    800027c4:	07b53423          	sd	s11,104(a0)
    800027c8:	0005b083          	ld	ra,0(a1)
    800027cc:	0085b103          	ld	sp,8(a1)
    800027d0:	6980                	ld	s0,16(a1)
    800027d2:	6d84                	ld	s1,24(a1)
    800027d4:	0205b903          	ld	s2,32(a1)
    800027d8:	0285b983          	ld	s3,40(a1)
    800027dc:	0305ba03          	ld	s4,48(a1)
    800027e0:	0385ba83          	ld	s5,56(a1)
    800027e4:	0405bb03          	ld	s6,64(a1)
    800027e8:	0485bb83          	ld	s7,72(a1)
    800027ec:	0505bc03          	ld	s8,80(a1)
    800027f0:	0585bc83          	ld	s9,88(a1)
    800027f4:	0605bd03          	ld	s10,96(a1)
    800027f8:	0685bd83          	ld	s11,104(a1)
    800027fc:	8082                	ret

00000000800027fe <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800027fe:	1141                	addi	sp,sp,-16
    80002800:	e406                	sd	ra,8(sp)
    80002802:	e022                	sd	s0,0(sp)
    80002804:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002806:	00006597          	auipc	a1,0x6
    8000280a:	af258593          	addi	a1,a1,-1294 # 800082f8 <states.0+0x30>
    8000280e:	00015517          	auipc	a0,0x15
    80002812:	d7250513          	addi	a0,a0,-654 # 80017580 <tickslock>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	330080e7          	jalr	816(ra) # 80000b46 <initlock>
}
    8000281e:	60a2                	ld	ra,8(sp)
    80002820:	6402                	ld	s0,0(sp)
    80002822:	0141                	addi	sp,sp,16
    80002824:	8082                	ret

0000000080002826 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002826:	1141                	addi	sp,sp,-16
    80002828:	e422                	sd	s0,8(sp)
    8000282a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282c:	00003797          	auipc	a5,0x3
    80002830:	67478793          	addi	a5,a5,1652 # 80005ea0 <kernelvec>
    80002834:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002838:	6422                	ld	s0,8(sp)
    8000283a:	0141                	addi	sp,sp,16
    8000283c:	8082                	ret

000000008000283e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000283e:	1141                	addi	sp,sp,-16
    80002840:	e406                	sd	ra,8(sp)
    80002842:	e022                	sd	s0,0(sp)
    80002844:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	166080e7          	jalr	358(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002852:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002854:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002858:	00004617          	auipc	a2,0x4
    8000285c:	7a860613          	addi	a2,a2,1960 # 80007000 <_trampoline>
    80002860:	00004697          	auipc	a3,0x4
    80002864:	7a068693          	addi	a3,a3,1952 # 80007000 <_trampoline>
    80002868:	8e91                	sub	a3,a3,a2
    8000286a:	040007b7          	lui	a5,0x4000
    8000286e:	17fd                	addi	a5,a5,-1
    80002870:	07b2                	slli	a5,a5,0xc
    80002872:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002874:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002878:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000287a:	180026f3          	csrr	a3,satp
    8000287e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002880:	7138                	ld	a4,96(a0)
    80002882:	6134                	ld	a3,64(a0)
    80002884:	6585                	lui	a1,0x1
    80002886:	96ae                	add	a3,a3,a1
    80002888:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000288a:	7138                	ld	a4,96(a0)
    8000288c:	00000697          	auipc	a3,0x0
    80002890:	13e68693          	addi	a3,a3,318 # 800029ca <usertrap>
    80002894:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002896:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002898:	8692                	mv	a3,tp
    8000289a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028a0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ac:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ae:	6f18                	ld	a4,24(a4)
    800028b0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b4:	6d28                	ld	a0,88(a0)
    800028b6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028b8:	00004717          	auipc	a4,0x4
    800028bc:	7e470713          	addi	a4,a4,2020 # 8000709c <userret>
    800028c0:	8f11                	sub	a4,a4,a2
    800028c2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028c4:	577d                	li	a4,-1
    800028c6:	177e                	slli	a4,a4,0x3f
    800028c8:	8d59                	or	a0,a0,a4
    800028ca:	9782                	jalr	a5
}
    800028cc:	60a2                	ld	ra,8(sp)
    800028ce:	6402                	ld	s0,0(sp)
    800028d0:	0141                	addi	sp,sp,16
    800028d2:	8082                	ret

00000000800028d4 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028d4:	1101                	addi	sp,sp,-32
    800028d6:	ec06                	sd	ra,24(sp)
    800028d8:	e822                	sd	s0,16(sp)
    800028da:	e426                	sd	s1,8(sp)
    800028dc:	e04a                	sd	s2,0(sp)
    800028de:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e0:	00015917          	auipc	s2,0x15
    800028e4:	ca090913          	addi	s2,s2,-864 # 80017580 <tickslock>
    800028e8:	854a                	mv	a0,s2
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	2ec080e7          	jalr	748(ra) # 80000bd6 <acquire>
  ticks++;
    800028f2:	00006497          	auipc	s1,0x6
    800028f6:	fee48493          	addi	s1,s1,-18 # 800088e0 <ticks>
    800028fa:	409c                	lw	a5,0(s1)
    800028fc:	2785                	addiw	a5,a5,1
    800028fe:	c09c                	sw	a5,0(s1)
  update_time();
    80002900:	00000097          	auipc	ra,0x0
    80002904:	e36080e7          	jalr	-458(ra) # 80002736 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002908:	8526                	mv	a0,s1
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	7d6080e7          	jalr	2006(ra) # 800020e0 <wakeup>
  release(&tickslock);
    80002912:	854a                	mv	a0,s2
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	376080e7          	jalr	886(ra) # 80000c8a <release>
}
    8000291c:	60e2                	ld	ra,24(sp)
    8000291e:	6442                	ld	s0,16(sp)
    80002920:	64a2                	ld	s1,8(sp)
    80002922:	6902                	ld	s2,0(sp)
    80002924:	6105                	addi	sp,sp,32
    80002926:	8082                	ret

0000000080002928 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002928:	1101                	addi	sp,sp,-32
    8000292a:	ec06                	sd	ra,24(sp)
    8000292c:	e822                	sd	s0,16(sp)
    8000292e:	e426                	sd	s1,8(sp)
    80002930:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002932:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002936:	00074d63          	bltz	a4,80002950 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    8000293a:	57fd                	li	a5,-1
    8000293c:	17fe                	slli	a5,a5,0x3f
    8000293e:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002940:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002942:	06f70363          	beq	a4,a5,800029a8 <devintr+0x80>
  }
}
    80002946:	60e2                	ld	ra,24(sp)
    80002948:	6442                	ld	s0,16(sp)
    8000294a:	64a2                	ld	s1,8(sp)
    8000294c:	6105                	addi	sp,sp,32
    8000294e:	8082                	ret
      (scause & 0xff) == 9)
    80002950:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002954:	46a5                	li	a3,9
    80002956:	fed792e3          	bne	a5,a3,8000293a <devintr+0x12>
    int irq = plic_claim();
    8000295a:	00003097          	auipc	ra,0x3
    8000295e:	64e080e7          	jalr	1614(ra) # 80005fa8 <plic_claim>
    80002962:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002964:	47a9                	li	a5,10
    80002966:	02f50763          	beq	a0,a5,80002994 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    8000296a:	4785                	li	a5,1
    8000296c:	02f50963          	beq	a0,a5,8000299e <devintr+0x76>
    return 1;
    80002970:	4505                	li	a0,1
    else if (irq)
    80002972:	d8f1                	beqz	s1,80002946 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002974:	85a6                	mv	a1,s1
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	98a50513          	addi	a0,a0,-1654 # 80008300 <states.0+0x38>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	c0a080e7          	jalr	-1014(ra) # 80000588 <printf>
      plic_complete(irq);
    80002986:	8526                	mv	a0,s1
    80002988:	00003097          	auipc	ra,0x3
    8000298c:	644080e7          	jalr	1604(ra) # 80005fcc <plic_complete>
    return 1;
    80002990:	4505                	li	a0,1
    80002992:	bf55                	j	80002946 <devintr+0x1e>
      uartintr();
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	006080e7          	jalr	6(ra) # 8000099a <uartintr>
    8000299c:	b7ed                	j	80002986 <devintr+0x5e>
      virtio_disk_intr();
    8000299e:	00004097          	auipc	ra,0x4
    800029a2:	afa080e7          	jalr	-1286(ra) # 80006498 <virtio_disk_intr>
    800029a6:	b7c5                	j	80002986 <devintr+0x5e>
    if (cpuid() == 0)
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	fd8080e7          	jalr	-40(ra) # 80001980 <cpuid>
    800029b0:	c901                	beqz	a0,800029c0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029b2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029b8:	14479073          	csrw	sip,a5
    return 2;
    800029bc:	4509                	li	a0,2
    800029be:	b761                	j	80002946 <devintr+0x1e>
      clockintr();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	f14080e7          	jalr	-236(ra) # 800028d4 <clockintr>
    800029c8:	b7ed                	j	800029b2 <devintr+0x8a>

00000000800029ca <usertrap>:
{
    800029ca:	1101                	addi	sp,sp,-32
    800029cc:	ec06                	sd	ra,24(sp)
    800029ce:	e822                	sd	s0,16(sp)
    800029d0:	e426                	sd	s1,8(sp)
    800029d2:	e04a                	sd	s2,0(sp)
    800029d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d6:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029da:	1007f793          	andi	a5,a5,256
    800029de:	ebb9                	bnez	a5,80002a34 <usertrap+0x6a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e0:	00003797          	auipc	a5,0x3
    800029e4:	4c078793          	addi	a5,a5,1216 # 80005ea0 <kernelvec>
    800029e8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800029f4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029f6:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f8:	14102773          	csrr	a4,sepc
    800029fc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a02:	47a1                	li	a5,8
    80002a04:	04f70063          	beq	a4,a5,80002a44 <usertrap+0x7a>
  else if ((which_dev = devintr()) != 0)
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	f20080e7          	jalr	-224(ra) # 80002928 <devintr>
    80002a10:	892a                	mv	s2,a0
    80002a12:	cd5d                	beqz	a0,80002ad0 <usertrap+0x106>
if (which_dev == 2 && p->alarm == 0) {
    80002a14:	4789                	li	a5,2
    80002a16:	04f51b63          	bne	a0,a5,80002a6c <usertrap+0xa2>
    80002a1a:	5cbc                	lw	a5,120(s1)
    80002a1c:	cfb5                	beqz	a5,80002a98 <usertrap+0xce>
  if (killed(p))
    80002a1e:	8526                	mv	a0,s1
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	910080e7          	jalr	-1776(ra) # 80002330 <killed>
    80002a28:	e975                	bnez	a0,80002b1c <usertrap+0x152>
    yield();
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	616080e7          	jalr	1558(ra) # 80002040 <yield>
    80002a32:	a099                	j	80002a78 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	8ec50513          	addi	a0,a0,-1812 # 80008320 <states.0+0x58>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
    if (killed(p))
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	8ec080e7          	jalr	-1812(ra) # 80002330 <killed>
    80002a4c:	e121                	bnez	a0,80002a8c <usertrap+0xc2>
    p->trapframe->epc += 4;
    80002a4e:	70b8                	ld	a4,96(s1)
    80002a50:	6f1c                	ld	a5,24(a4)
    80002a52:	0791                	addi	a5,a5,4
    80002a54:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5e:	10079073          	csrw	sstatus,a5
    syscall();
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	310080e7          	jalr	784(ra) # 80002d72 <syscall>
  int which_dev = 0;
    80002a6a:	4901                	li	s2,0
  if (killed(p))
    80002a6c:	8526                	mv	a0,s1
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	8c2080e7          	jalr	-1854(ra) # 80002330 <killed>
    80002a76:	e951                	bnez	a0,80002b0a <usertrap+0x140>
  usertrapret();
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	dc6080e7          	jalr	-570(ra) # 8000283e <usertrapret>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6902                	ld	s2,0(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
      exit(-1);
    80002a8c:	557d                	li	a0,-1
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	722080e7          	jalr	1826(ra) # 800021b0 <exit>
    80002a96:	bf65                	j	80002a4e <usertrap+0x84>
    p->alarm = 1;
    80002a98:	4785                	li	a5,1
    80002a9a:	dcbc                	sw	a5,120(s1)
    struct trapframe *tf=kalloc();
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	04a080e7          	jalr	74(ra) # 80000ae6 <kalloc>
    80002aa4:	892a                	mv	s2,a0
    memmove(tf, p->trapframe, sizeof(*tf));
    80002aa6:	12000613          	li	a2,288
    80002aaa:	70ac                	ld	a1,96(s1)
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	282080e7          	jalr	642(ra) # 80000d2e <memmove>
    p->alram_tf = tf;
    80002ab4:	0724b823          	sd	s2,112(s1)
    p->current_ticks++;
    80002ab8:	54fc                	lw	a5,108(s1)
    80002aba:	2785                	addiw	a5,a5,1
    80002abc:	0007871b          	sext.w	a4,a5
    80002ac0:	d4fc                	sw	a5,108(s1)
    if (p->current_ticks >= p->ticks) {
    80002ac2:	54bc                	lw	a5,104(s1)
    80002ac4:	f4f74de3          	blt	a4,a5,80002a1e <usertrap+0x54>
        p->trapframe->epc = p->handler;
    80002ac8:	70bc                	ld	a5,96(s1)
    80002aca:	68b8                	ld	a4,80(s1)
    80002acc:	ef98                	sd	a4,24(a5)
    80002ace:	bf81                	j	80002a1e <usertrap+0x54>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ad4:	5890                	lw	a2,48(s1)
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	86a50513          	addi	a0,a0,-1942 # 80008340 <states.0+0x78>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	aaa080e7          	jalr	-1366(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	88250513          	addi	a0,a0,-1918 # 80008370 <states.0+0xa8>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a92080e7          	jalr	-1390(ra) # 80000588 <printf>
    setkilled(p);
    80002afe:	8526                	mv	a0,s1
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	804080e7          	jalr	-2044(ra) # 80002304 <setkilled>
    80002b08:	b795                	j	80002a6c <usertrap+0xa2>
    exit(-1);
    80002b0a:	557d                	li	a0,-1
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	6a4080e7          	jalr	1700(ra) # 800021b0 <exit>
  if (which_dev == 2)
    80002b14:	4789                	li	a5,2
    80002b16:	f6f911e3          	bne	s2,a5,80002a78 <usertrap+0xae>
    80002b1a:	bf01                	j	80002a2a <usertrap+0x60>
    exit(-1);
    80002b1c:	557d                	li	a0,-1
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	692080e7          	jalr	1682(ra) # 800021b0 <exit>
  if (which_dev == 2)
    80002b26:	b711                	j	80002a2a <usertrap+0x60>

0000000080002b28 <kerneltrap>:
{
    80002b28:	7179                	addi	sp,sp,-48
    80002b2a:	f406                	sd	ra,40(sp)
    80002b2c:	f022                	sd	s0,32(sp)
    80002b2e:	ec26                	sd	s1,24(sp)
    80002b30:	e84a                	sd	s2,16(sp)
    80002b32:	e44e                	sd	s3,8(sp)
    80002b34:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b36:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b42:	1004f793          	andi	a5,s1,256
    80002b46:	cb85                	beqz	a5,80002b76 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b4c:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b4e:	ef85                	bnez	a5,80002b86 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	dd8080e7          	jalr	-552(ra) # 80002928 <devintr>
    80002b58:	cd1d                	beqz	a0,80002b96 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b5a:	4789                	li	a5,2
    80002b5c:	06f50a63          	beq	a0,a5,80002bd0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b60:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b64:	10049073          	csrw	sstatus,s1
}
    80002b68:	70a2                	ld	ra,40(sp)
    80002b6a:	7402                	ld	s0,32(sp)
    80002b6c:	64e2                	ld	s1,24(sp)
    80002b6e:	6942                	ld	s2,16(sp)
    80002b70:	69a2                	ld	s3,8(sp)
    80002b72:	6145                	addi	sp,sp,48
    80002b74:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	81a50513          	addi	a0,a0,-2022 # 80008390 <states.0+0xc8>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	9c0080e7          	jalr	-1600(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	83250513          	addi	a0,a0,-1998 # 800083b8 <states.0+0xf0>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b96:	85ce                	mv	a1,s3
    80002b98:	00006517          	auipc	a0,0x6
    80002b9c:	84050513          	addi	a0,a0,-1984 # 800083d8 <states.0+0x110>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9e8080e7          	jalr	-1560(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bac:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	83850513          	addi	a0,a0,-1992 # 800083e8 <states.0+0x120>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9d0080e7          	jalr	-1584(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	84050513          	addi	a0,a0,-1984 # 80008400 <states.0+0x138>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	976080e7          	jalr	-1674(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	ddc080e7          	jalr	-548(ra) # 800019ac <myproc>
    80002bd8:	d541                	beqz	a0,80002b60 <kerneltrap+0x38>
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	dd2080e7          	jalr	-558(ra) # 800019ac <myproc>
    80002be2:	4d18                	lw	a4,24(a0)
    80002be4:	4791                	li	a5,4
    80002be6:	f6f71de3          	bne	a4,a5,80002b60 <kerneltrap+0x38>
    yield();
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	456080e7          	jalr	1110(ra) # 80002040 <yield>
    80002bf2:	b7bd                	j	80002b60 <kerneltrap+0x38>

0000000080002bf4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	1000                	addi	s0,sp,32
    80002bfe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	dac080e7          	jalr	-596(ra) # 800019ac <myproc>
  switch (n) {
    80002c08:	4795                	li	a5,5
    80002c0a:	0497e163          	bltu	a5,s1,80002c4c <argraw+0x58>
    80002c0e:	048a                	slli	s1,s1,0x2
    80002c10:	00006717          	auipc	a4,0x6
    80002c14:	82870713          	addi	a4,a4,-2008 # 80008438 <states.0+0x170>
    80002c18:	94ba                	add	s1,s1,a4
    80002c1a:	409c                	lw	a5,0(s1)
    80002c1c:	97ba                	add	a5,a5,a4
    80002c1e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c20:	713c                	ld	a5,96(a0)
    80002c22:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret
    return p->trapframe->a1;
    80002c2e:	713c                	ld	a5,96(a0)
    80002c30:	7fa8                	ld	a0,120(a5)
    80002c32:	bfcd                	j	80002c24 <argraw+0x30>
    return p->trapframe->a2;
    80002c34:	713c                	ld	a5,96(a0)
    80002c36:	63c8                	ld	a0,128(a5)
    80002c38:	b7f5                	j	80002c24 <argraw+0x30>
    return p->trapframe->a3;
    80002c3a:	713c                	ld	a5,96(a0)
    80002c3c:	67c8                	ld	a0,136(a5)
    80002c3e:	b7dd                	j	80002c24 <argraw+0x30>
    return p->trapframe->a4;
    80002c40:	713c                	ld	a5,96(a0)
    80002c42:	6bc8                	ld	a0,144(a5)
    80002c44:	b7c5                	j	80002c24 <argraw+0x30>
    return p->trapframe->a5;
    80002c46:	713c                	ld	a5,96(a0)
    80002c48:	6fc8                	ld	a0,152(a5)
    80002c4a:	bfe9                	j	80002c24 <argraw+0x30>
  panic("argraw");
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	7c450513          	addi	a0,a0,1988 # 80008410 <states.0+0x148>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>

0000000080002c5c <fetchaddr>:
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	e04a                	sd	s2,0(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84aa                	mv	s1,a0
    80002c6a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	d40080e7          	jalr	-704(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c74:	653c                	ld	a5,72(a0)
    80002c76:	02f4f863          	bgeu	s1,a5,80002ca6 <fetchaddr+0x4a>
    80002c7a:	00848713          	addi	a4,s1,8
    80002c7e:	02e7e663          	bltu	a5,a4,80002caa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c82:	46a1                	li	a3,8
    80002c84:	8626                	mv	a2,s1
    80002c86:	85ca                	mv	a1,s2
    80002c88:	6d28                	ld	a0,88(a0)
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	a6a080e7          	jalr	-1430(ra) # 800016f4 <copyin>
    80002c92:	00a03533          	snez	a0,a0
    80002c96:	40a00533          	neg	a0,a0
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6902                	ld	s2,0(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret
    return -1;
    80002ca6:	557d                	li	a0,-1
    80002ca8:	bfcd                	j	80002c9a <fetchaddr+0x3e>
    80002caa:	557d                	li	a0,-1
    80002cac:	b7fd                	j	80002c9a <fetchaddr+0x3e>

0000000080002cae <fetchstr>:
{
    80002cae:	7179                	addi	sp,sp,-48
    80002cb0:	f406                	sd	ra,40(sp)
    80002cb2:	f022                	sd	s0,32(sp)
    80002cb4:	ec26                	sd	s1,24(sp)
    80002cb6:	e84a                	sd	s2,16(sp)
    80002cb8:	e44e                	sd	s3,8(sp)
    80002cba:	1800                	addi	s0,sp,48
    80002cbc:	892a                	mv	s2,a0
    80002cbe:	84ae                	mv	s1,a1
    80002cc0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	cea080e7          	jalr	-790(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cca:	86ce                	mv	a3,s3
    80002ccc:	864a                	mv	a2,s2
    80002cce:	85a6                	mv	a1,s1
    80002cd0:	6d28                	ld	a0,88(a0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	ab0080e7          	jalr	-1360(ra) # 80001782 <copyinstr>
    80002cda:	00054e63          	bltz	a0,80002cf6 <fetchstr+0x48>
  return strlen(buf);
    80002cde:	8526                	mv	a0,s1
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	16e080e7          	jalr	366(ra) # 80000e4e <strlen>
}
    80002ce8:	70a2                	ld	ra,40(sp)
    80002cea:	7402                	ld	s0,32(sp)
    80002cec:	64e2                	ld	s1,24(sp)
    80002cee:	6942                	ld	s2,16(sp)
    80002cf0:	69a2                	ld	s3,8(sp)
    80002cf2:	6145                	addi	sp,sp,48
    80002cf4:	8082                	ret
    return -1;
    80002cf6:	557d                	li	a0,-1
    80002cf8:	bfc5                	j	80002ce8 <fetchstr+0x3a>

0000000080002cfa <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	1000                	addi	s0,sp,32
    80002d04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	eee080e7          	jalr	-274(ra) # 80002bf4 <argraw>
    80002d0e:	c088                	sw	a0,0(s1)
}
    80002d10:	60e2                	ld	ra,24(sp)
    80002d12:	6442                	ld	s0,16(sp)
    80002d14:	64a2                	ld	s1,8(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret

0000000080002d1a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	e426                	sd	s1,8(sp)
    80002d22:	1000                	addi	s0,sp,32
    80002d24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	ece080e7          	jalr	-306(ra) # 80002bf4 <argraw>
    80002d2e:	e088                	sd	a0,0(s1)
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret

0000000080002d3a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d3a:	7179                	addi	sp,sp,-48
    80002d3c:	f406                	sd	ra,40(sp)
    80002d3e:	f022                	sd	s0,32(sp)
    80002d40:	ec26                	sd	s1,24(sp)
    80002d42:	e84a                	sd	s2,16(sp)
    80002d44:	1800                	addi	s0,sp,48
    80002d46:	84ae                	mv	s1,a1
    80002d48:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d4a:	fd840593          	addi	a1,s0,-40
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	fcc080e7          	jalr	-52(ra) # 80002d1a <argaddr>
  return fetchstr(addr, buf, max);
    80002d56:	864a                	mv	a2,s2
    80002d58:	85a6                	mv	a1,s1
    80002d5a:	fd843503          	ld	a0,-40(s0)
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	f50080e7          	jalr	-176(ra) # 80002cae <fetchstr>
}
    80002d66:	70a2                	ld	ra,40(sp)
    80002d68:	7402                	ld	s0,32(sp)
    80002d6a:	64e2                	ld	s1,24(sp)
    80002d6c:	6942                	ld	s2,16(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret

0000000080002d72 <syscall>:

};

void
syscall(void)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	e04a                	sd	s2,0(sp)
    80002d7c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	c2e080e7          	jalr	-978(ra) # 800019ac <myproc>
    80002d86:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d88:	06053903          	ld	s2,96(a0)
    80002d8c:	0a893783          	ld	a5,168(s2)
    80002d90:	0007869b          	sext.w	a3,a5
  // if(num==SYS_read){
  //   readcountvalue++;
  // }
  if(num==SYS_read){
    80002d94:	4715                	li	a4,5
    80002d96:	02e68363          	beq	a3,a4,80002dbc <syscall+0x4a>
    p->readcount=p->readcount+1;
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d9a:	37fd                	addiw	a5,a5,-1
    80002d9c:	4761                	li	a4,24
    80002d9e:	02f76a63          	bltu	a4,a5,80002dd2 <syscall+0x60>
    80002da2:	00369713          	slli	a4,a3,0x3
    80002da6:	00005797          	auipc	a5,0x5
    80002daa:	6aa78793          	addi	a5,a5,1706 # 80008450 <syscalls>
    80002dae:	97ba                	add	a5,a5,a4
    80002db0:	6398                	ld	a4,0(a5)
    80002db2:	c305                	beqz	a4,80002dd2 <syscall+0x60>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002db4:	9702                	jalr	a4
    80002db6:	06a93823          	sd	a0,112(s2)
    80002dba:	a815                	j	80002dee <syscall+0x7c>
    p->readcount=p->readcount+1;
    80002dbc:	5958                	lw	a4,52(a0)
    80002dbe:	2705                	addiw	a4,a4,1
    80002dc0:	d958                	sw	a4,52(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dc2:	37fd                	addiw	a5,a5,-1
    80002dc4:	4661                	li	a2,24
    80002dc6:	00002717          	auipc	a4,0x2
    80002dca:	74270713          	addi	a4,a4,1858 # 80005508 <sys_read>
    80002dce:	fef673e3          	bgeu	a2,a5,80002db4 <syscall+0x42>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dd2:	17848613          	addi	a2,s1,376
    80002dd6:	588c                	lw	a1,48(s1)
    80002dd8:	00005517          	auipc	a0,0x5
    80002ddc:	64050513          	addi	a0,a0,1600 # 80008418 <states.0+0x150>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	7a8080e7          	jalr	1960(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002de8:	70bc                	ld	a5,96(s1)
    80002dea:	577d                	li	a4,-1
    80002dec:	fbb8                	sd	a4,112(a5)
  }
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	64a2                	ld	s1,8(sp)
    80002df4:	6902                	ld	s2,0(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e02:	fec40593          	addi	a1,s0,-20
    80002e06:	4501                	li	a0,0
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	ef2080e7          	jalr	-270(ra) # 80002cfa <argint>
  exit(n);
    80002e10:	fec42503          	lw	a0,-20(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	39c080e7          	jalr	924(ra) # 800021b0 <exit>
  return 0; // not reached
}
    80002e1c:	4501                	li	a0,0
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e26:	1141                	addi	sp,sp,-16
    80002e28:	e406                	sd	ra,8(sp)
    80002e2a:	e022                	sd	s0,0(sp)
    80002e2c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	b7e080e7          	jalr	-1154(ra) # 800019ac <myproc>
}
    80002e36:	5908                	lw	a0,48(a0)
    80002e38:	60a2                	ld	ra,8(sp)
    80002e3a:	6402                	ld	s0,0(sp)
    80002e3c:	0141                	addi	sp,sp,16
    80002e3e:	8082                	ret

0000000080002e40 <sys_fork>:

uint64
sys_fork(void)
{
    80002e40:	1141                	addi	sp,sp,-16
    80002e42:	e406                	sd	ra,8(sp)
    80002e44:	e022                	sd	s0,0(sp)
    80002e46:	0800                	addi	s0,sp,16
  return fork();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	f42080e7          	jalr	-190(ra) # 80001d8a <fork>
}
    80002e50:	60a2                	ld	ra,8(sp)
    80002e52:	6402                	ld	s0,0(sp)
    80002e54:	0141                	addi	sp,sp,16
    80002e56:	8082                	ret

0000000080002e58 <sys_wait>:

uint64
sys_wait(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e60:	fe840593          	addi	a1,s0,-24
    80002e64:	4501                	li	a0,0
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	eb4080e7          	jalr	-332(ra) # 80002d1a <argaddr>
  return wait(p);
    80002e6e:	fe843503          	ld	a0,-24(s0)
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	4f0080e7          	jalr	1264(ra) # 80002362 <wait>
}
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e82:	7179                	addi	sp,sp,-48
    80002e84:	f406                	sd	ra,40(sp)
    80002e86:	f022                	sd	s0,32(sp)
    80002e88:	ec26                	sd	s1,24(sp)
    80002e8a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e8c:	fdc40593          	addi	a1,s0,-36
    80002e90:	4501                	li	a0,0
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	e68080e7          	jalr	-408(ra) # 80002cfa <argint>
  addr = myproc()->sz;
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	b12080e7          	jalr	-1262(ra) # 800019ac <myproc>
    80002ea2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002ea4:	fdc42503          	lw	a0,-36(s0)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	e86080e7          	jalr	-378(ra) # 80001d2e <growproc>
    80002eb0:	00054863          	bltz	a0,80002ec0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	70a2                	ld	ra,40(sp)
    80002eb8:	7402                	ld	s0,32(sp)
    80002eba:	64e2                	ld	s1,24(sp)
    80002ebc:	6145                	addi	sp,sp,48
    80002ebe:	8082                	ret
    return -1;
    80002ec0:	54fd                	li	s1,-1
    80002ec2:	bfcd                	j	80002eb4 <sys_sbrk+0x32>

0000000080002ec4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ec4:	7139                	addi	sp,sp,-64
    80002ec6:	fc06                	sd	ra,56(sp)
    80002ec8:	f822                	sd	s0,48(sp)
    80002eca:	f426                	sd	s1,40(sp)
    80002ecc:	f04a                	sd	s2,32(sp)
    80002ece:	ec4e                	sd	s3,24(sp)
    80002ed0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ed2:	fcc40593          	addi	a1,s0,-52
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	e22080e7          	jalr	-478(ra) # 80002cfa <argint>
  acquire(&tickslock);
    80002ee0:	00014517          	auipc	a0,0x14
    80002ee4:	6a050513          	addi	a0,a0,1696 # 80017580 <tickslock>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	cee080e7          	jalr	-786(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ef0:	00006917          	auipc	s2,0x6
    80002ef4:	9f092903          	lw	s2,-1552(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80002ef8:	fcc42783          	lw	a5,-52(s0)
    80002efc:	cf9d                	beqz	a5,80002f3a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002efe:	00014997          	auipc	s3,0x14
    80002f02:	68298993          	addi	s3,s3,1666 # 80017580 <tickslock>
    80002f06:	00006497          	auipc	s1,0x6
    80002f0a:	9da48493          	addi	s1,s1,-1574 # 800088e0 <ticks>
    if (killed(myproc()))
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	a9e080e7          	jalr	-1378(ra) # 800019ac <myproc>
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	41a080e7          	jalr	1050(ra) # 80002330 <killed>
    80002f1e:	ed15                	bnez	a0,80002f5a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f20:	85ce                	mv	a1,s3
    80002f22:	8526                	mv	a0,s1
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	158080e7          	jalr	344(ra) # 8000207c <sleep>
  while (ticks - ticks0 < n)
    80002f2c:	409c                	lw	a5,0(s1)
    80002f2e:	412787bb          	subw	a5,a5,s2
    80002f32:	fcc42703          	lw	a4,-52(s0)
    80002f36:	fce7ece3          	bltu	a5,a4,80002f0e <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f3a:	00014517          	auipc	a0,0x14
    80002f3e:	64650513          	addi	a0,a0,1606 # 80017580 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	d48080e7          	jalr	-696(ra) # 80000c8a <release>
  return 0;
    80002f4a:	4501                	li	a0,0
}
    80002f4c:	70e2                	ld	ra,56(sp)
    80002f4e:	7442                	ld	s0,48(sp)
    80002f50:	74a2                	ld	s1,40(sp)
    80002f52:	7902                	ld	s2,32(sp)
    80002f54:	69e2                	ld	s3,24(sp)
    80002f56:	6121                	addi	sp,sp,64
    80002f58:	8082                	ret
      release(&tickslock);
    80002f5a:	00014517          	auipc	a0,0x14
    80002f5e:	62650513          	addi	a0,a0,1574 # 80017580 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d28080e7          	jalr	-728(ra) # 80000c8a <release>
      return -1;
    80002f6a:	557d                	li	a0,-1
    80002f6c:	b7c5                	j	80002f4c <sys_sleep+0x88>

0000000080002f6e <sys_kill>:

uint64
sys_kill(void)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f76:	fec40593          	addi	a1,s0,-20
    80002f7a:	4501                	li	a0,0
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	d7e080e7          	jalr	-642(ra) # 80002cfa <argint>
  return kill(pid);
    80002f84:	fec42503          	lw	a0,-20(s0)
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	30a080e7          	jalr	778(ra) # 80002292 <kill>
}
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	6105                	addi	sp,sp,32
    80002f96:	8082                	ret

0000000080002f98 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	e426                	sd	s1,8(sp)
    80002fa0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	5de50513          	addi	a0,a0,1502 # 80017580 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c2c080e7          	jalr	-980(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fb2:	00006497          	auipc	s1,0x6
    80002fb6:	92e4a483          	lw	s1,-1746(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002fba:	00014517          	auipc	a0,0x14
    80002fbe:	5c650513          	addi	a0,a0,1478 # 80017580 <tickslock>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	cc8080e7          	jalr	-824(ra) # 80000c8a <release>
  return xticks;
}
    80002fca:	02049513          	slli	a0,s1,0x20
    80002fce:	9101                	srli	a0,a0,0x20
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	64a2                	ld	s1,8(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <sys_waitx>:

uint64
sys_waitx(void)
{
    80002fda:	7139                	addi	sp,sp,-64
    80002fdc:	fc06                	sd	ra,56(sp)
    80002fde:	f822                	sd	s0,48(sp)
    80002fe0:	f426                	sd	s1,40(sp)
    80002fe2:	f04a                	sd	s2,32(sp)
    80002fe4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002fe6:	fd840593          	addi	a1,s0,-40
    80002fea:	4501                	li	a0,0
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	d2e080e7          	jalr	-722(ra) # 80002d1a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002ff4:	fd040593          	addi	a1,s0,-48
    80002ff8:	4505                	li	a0,1
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	d20080e7          	jalr	-736(ra) # 80002d1a <argaddr>
  argaddr(2, &addr2);
    80003002:	fc840593          	addi	a1,s0,-56
    80003006:	4509                	li	a0,2
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	d12080e7          	jalr	-750(ra) # 80002d1a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003010:	fc040613          	addi	a2,s0,-64
    80003014:	fc440593          	addi	a1,s0,-60
    80003018:	fd843503          	ld	a0,-40(s0)
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	5ce080e7          	jalr	1486(ra) # 800025ea <waitx>
    80003024:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	986080e7          	jalr	-1658(ra) # 800019ac <myproc>
    8000302e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003030:	4691                	li	a3,4
    80003032:	fc440613          	addi	a2,s0,-60
    80003036:	fd043583          	ld	a1,-48(s0)
    8000303a:	6d28                	ld	a0,88(a0)
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	62c080e7          	jalr	1580(ra) # 80001668 <copyout>
    return -1;
    80003044:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003046:	00054f63          	bltz	a0,80003064 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000304a:	4691                	li	a3,4
    8000304c:	fc040613          	addi	a2,s0,-64
    80003050:	fc843583          	ld	a1,-56(s0)
    80003054:	6ca8                	ld	a0,88(s1)
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	612080e7          	jalr	1554(ra) # 80001668 <copyout>
    8000305e:	00054a63          	bltz	a0,80003072 <sys_waitx+0x98>
    return -1;
  return ret;
    80003062:	87ca                	mv	a5,s2
}
    80003064:	853e                	mv	a0,a5
    80003066:	70e2                	ld	ra,56(sp)
    80003068:	7442                	ld	s0,48(sp)
    8000306a:	74a2                	ld	s1,40(sp)
    8000306c:	7902                	ld	s2,32(sp)
    8000306e:	6121                	addi	sp,sp,64
    80003070:	8082                	ret
    return -1;
    80003072:	57fd                	li	a5,-1
    80003074:	bfc5                	j	80003064 <sys_waitx+0x8a>

0000000080003076 <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    80003076:	1141                	addi	sp,sp,-16
    80003078:	e406                	sd	ra,8(sp)
    8000307a:	e022                	sd	s0,0(sp)
    8000307c:	0800                	addi	s0,sp,16
  return myproc()->readcount;
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	92e080e7          	jalr	-1746(ra) # 800019ac <myproc>
}
    80003086:	5948                	lw	a0,52(a0)
    80003088:	60a2                	ld	ra,8(sp)
    8000308a:	6402                	ld	s0,0(sp)
    8000308c:	0141                	addi	sp,sp,16
    8000308e:	8082                	ret

0000000080003090 <sys_sigalarm>:
uint64 
sys_sigalarm(void)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	1000                	addi	s0,sp,32
  // if(argint(0,&ticks)<0)

  //  if (argint(0,&ticks) < 0 || argaddr(1, &addr) < 0) {
  //       return -1;
  //   }
  argint(0,&ticks);
    80003098:	fe440593          	addi	a1,s0,-28
    8000309c:	4501                	li	a0,0
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	c5c080e7          	jalr	-932(ra) # 80002cfa <argint>
  argaddr(1,&addr);
    800030a6:	fe840593          	addi	a1,s0,-24
    800030aa:	4505                	li	a0,1
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	c6e080e7          	jalr	-914(ra) # 80002d1a <argaddr>

  myproc()->handler = addr;
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	8f8080e7          	jalr	-1800(ra) # 800019ac <myproc>
    800030bc:	fe843783          	ld	a5,-24(s0)
    800030c0:	e93c                	sd	a5,80(a0)
  myproc()->ticks = ticks;
    800030c2:	fffff097          	auipc	ra,0xfffff
    800030c6:	8ea080e7          	jalr	-1814(ra) # 800019ac <myproc>
    800030ca:	fe442783          	lw	a5,-28(s0)
    800030ce:	d53c                	sw	a5,104(a0)

  return 0;
}
    800030d0:	4501                	li	a0,0
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <sys_sigreturn>:
uint64 sys_sigreturn(void)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	8c8080e7          	jalr	-1848(ra) # 800019ac <myproc>
    800030ec:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alram_tf, PGSIZE);
    800030ee:	6605                	lui	a2,0x1
    800030f0:	792c                	ld	a1,112(a0)
    800030f2:	7128                	ld	a0,96(a0)
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	c3a080e7          	jalr	-966(ra) # 80000d2e <memmove>

  kfree(p->alram_tf);
    800030fc:	78a8                	ld	a0,112(s1)
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	8ec080e7          	jalr	-1812(ra) # 800009ea <kfree>
  p->alram_tf = 0;
    80003106:	0604b823          	sd	zero,112(s1)
  p->alarm = 0;
    8000310a:	0604ac23          	sw	zero,120(s1)
  p->current_ticks = 0;
    8000310e:	0604a623          	sw	zero,108(s1)
  return 0;
    80003112:	4501                	li	a0,0
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	64a2                	ld	s1,8(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret

000000008000311e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000311e:	7179                	addi	sp,sp,-48
    80003120:	f406                	sd	ra,40(sp)
    80003122:	f022                	sd	s0,32(sp)
    80003124:	ec26                	sd	s1,24(sp)
    80003126:	e84a                	sd	s2,16(sp)
    80003128:	e44e                	sd	s3,8(sp)
    8000312a:	e052                	sd	s4,0(sp)
    8000312c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000312e:	00005597          	auipc	a1,0x5
    80003132:	3f258593          	addi	a1,a1,1010 # 80008520 <syscalls+0xd0>
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	46250513          	addi	a0,a0,1122 # 80017598 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	a08080e7          	jalr	-1528(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003146:	0001c797          	auipc	a5,0x1c
    8000314a:	45278793          	addi	a5,a5,1106 # 8001f598 <bcache+0x8000>
    8000314e:	0001c717          	auipc	a4,0x1c
    80003152:	6b270713          	addi	a4,a4,1714 # 8001f800 <bcache+0x8268>
    80003156:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000315a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315e:	00014497          	auipc	s1,0x14
    80003162:	45248493          	addi	s1,s1,1106 # 800175b0 <bcache+0x18>
    b->next = bcache.head.next;
    80003166:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003168:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000316a:	00005a17          	auipc	s4,0x5
    8000316e:	3bea0a13          	addi	s4,s4,958 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003172:	2b893783          	ld	a5,696(s2)
    80003176:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003178:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000317c:	85d2                	mv	a1,s4
    8000317e:	01048513          	addi	a0,s1,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	4c4080e7          	jalr	1220(ra) # 80004646 <initsleeplock>
    bcache.head.next->prev = b;
    8000318a:	2b893783          	ld	a5,696(s2)
    8000318e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003190:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003194:	45848493          	addi	s1,s1,1112
    80003198:	fd349de3          	bne	s1,s3,80003172 <binit+0x54>
  }
}
    8000319c:	70a2                	ld	ra,40(sp)
    8000319e:	7402                	ld	s0,32(sp)
    800031a0:	64e2                	ld	s1,24(sp)
    800031a2:	6942                	ld	s2,16(sp)
    800031a4:	69a2                	ld	s3,8(sp)
    800031a6:	6a02                	ld	s4,0(sp)
    800031a8:	6145                	addi	sp,sp,48
    800031aa:	8082                	ret

00000000800031ac <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031ac:	7179                	addi	sp,sp,-48
    800031ae:	f406                	sd	ra,40(sp)
    800031b0:	f022                	sd	s0,32(sp)
    800031b2:	ec26                	sd	s1,24(sp)
    800031b4:	e84a                	sd	s2,16(sp)
    800031b6:	e44e                	sd	s3,8(sp)
    800031b8:	1800                	addi	s0,sp,48
    800031ba:	892a                	mv	s2,a0
    800031bc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	3da50513          	addi	a0,a0,986 # 80017598 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	a10080e7          	jalr	-1520(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ce:	0001c497          	auipc	s1,0x1c
    800031d2:	6824b483          	ld	s1,1666(s1) # 8001f850 <bcache+0x82b8>
    800031d6:	0001c797          	auipc	a5,0x1c
    800031da:	62a78793          	addi	a5,a5,1578 # 8001f800 <bcache+0x8268>
    800031de:	02f48f63          	beq	s1,a5,8000321c <bread+0x70>
    800031e2:	873e                	mv	a4,a5
    800031e4:	a021                	j	800031ec <bread+0x40>
    800031e6:	68a4                	ld	s1,80(s1)
    800031e8:	02e48a63          	beq	s1,a4,8000321c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031ec:	449c                	lw	a5,8(s1)
    800031ee:	ff279ce3          	bne	a5,s2,800031e6 <bread+0x3a>
    800031f2:	44dc                	lw	a5,12(s1)
    800031f4:	ff3799e3          	bne	a5,s3,800031e6 <bread+0x3a>
      b->refcnt++;
    800031f8:	40bc                	lw	a5,64(s1)
    800031fa:	2785                	addiw	a5,a5,1
    800031fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	39a50513          	addi	a0,a0,922 # 80017598 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000320e:	01048513          	addi	a0,s1,16
    80003212:	00001097          	auipc	ra,0x1
    80003216:	46e080e7          	jalr	1134(ra) # 80004680 <acquiresleep>
      return b;
    8000321a:	a8b9                	j	80003278 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000321c:	0001c497          	auipc	s1,0x1c
    80003220:	62c4b483          	ld	s1,1580(s1) # 8001f848 <bcache+0x82b0>
    80003224:	0001c797          	auipc	a5,0x1c
    80003228:	5dc78793          	addi	a5,a5,1500 # 8001f800 <bcache+0x8268>
    8000322c:	00f48863          	beq	s1,a5,8000323c <bread+0x90>
    80003230:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003232:	40bc                	lw	a5,64(s1)
    80003234:	cf81                	beqz	a5,8000324c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003236:	64a4                	ld	s1,72(s1)
    80003238:	fee49de3          	bne	s1,a4,80003232 <bread+0x86>
  panic("bget: no buffers");
    8000323c:	00005517          	auipc	a0,0x5
    80003240:	2f450513          	addi	a0,a0,756 # 80008530 <syscalls+0xe0>
    80003244:	ffffd097          	auipc	ra,0xffffd
    80003248:	2fa080e7          	jalr	762(ra) # 8000053e <panic>
      b->dev = dev;
    8000324c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003250:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003254:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003258:	4785                	li	a5,1
    8000325a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000325c:	00014517          	auipc	a0,0x14
    80003260:	33c50513          	addi	a0,a0,828 # 80017598 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	a26080e7          	jalr	-1498(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000326c:	01048513          	addi	a0,s1,16
    80003270:	00001097          	auipc	ra,0x1
    80003274:	410080e7          	jalr	1040(ra) # 80004680 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003278:	409c                	lw	a5,0(s1)
    8000327a:	cb89                	beqz	a5,8000328c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000327c:	8526                	mv	a0,s1
    8000327e:	70a2                	ld	ra,40(sp)
    80003280:	7402                	ld	s0,32(sp)
    80003282:	64e2                	ld	s1,24(sp)
    80003284:	6942                	ld	s2,16(sp)
    80003286:	69a2                	ld	s3,8(sp)
    80003288:	6145                	addi	sp,sp,48
    8000328a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000328c:	4581                	li	a1,0
    8000328e:	8526                	mv	a0,s1
    80003290:	00003097          	auipc	ra,0x3
    80003294:	fd4080e7          	jalr	-44(ra) # 80006264 <virtio_disk_rw>
    b->valid = 1;
    80003298:	4785                	li	a5,1
    8000329a:	c09c                	sw	a5,0(s1)
  return b;
    8000329c:	b7c5                	j	8000327c <bread+0xd0>

000000008000329e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000329e:	1101                	addi	sp,sp,-32
    800032a0:	ec06                	sd	ra,24(sp)
    800032a2:	e822                	sd	s0,16(sp)
    800032a4:	e426                	sd	s1,8(sp)
    800032a6:	1000                	addi	s0,sp,32
    800032a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032aa:	0541                	addi	a0,a0,16
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	46e080e7          	jalr	1134(ra) # 8000471a <holdingsleep>
    800032b4:	cd01                	beqz	a0,800032cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032b6:	4585                	li	a1,1
    800032b8:	8526                	mv	a0,s1
    800032ba:	00003097          	auipc	ra,0x3
    800032be:	faa080e7          	jalr	-86(ra) # 80006264 <virtio_disk_rw>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret
    panic("bwrite");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	27c50513          	addi	a0,a0,636 # 80008548 <syscalls+0xf8>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>

00000000800032dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032dc:	1101                	addi	sp,sp,-32
    800032de:	ec06                	sd	ra,24(sp)
    800032e0:	e822                	sd	s0,16(sp)
    800032e2:	e426                	sd	s1,8(sp)
    800032e4:	e04a                	sd	s2,0(sp)
    800032e6:	1000                	addi	s0,sp,32
    800032e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ea:	01050913          	addi	s2,a0,16
    800032ee:	854a                	mv	a0,s2
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	42a080e7          	jalr	1066(ra) # 8000471a <holdingsleep>
    800032f8:	c92d                	beqz	a0,8000336a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032fa:	854a                	mv	a0,s2
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	3da080e7          	jalr	986(ra) # 800046d6 <releasesleep>

  acquire(&bcache.lock);
    80003304:	00014517          	auipc	a0,0x14
    80003308:	29450513          	addi	a0,a0,660 # 80017598 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	8ca080e7          	jalr	-1846(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003314:	40bc                	lw	a5,64(s1)
    80003316:	37fd                	addiw	a5,a5,-1
    80003318:	0007871b          	sext.w	a4,a5
    8000331c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000331e:	eb05                	bnez	a4,8000334e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003320:	68bc                	ld	a5,80(s1)
    80003322:	64b8                	ld	a4,72(s1)
    80003324:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003326:	64bc                	ld	a5,72(s1)
    80003328:	68b8                	ld	a4,80(s1)
    8000332a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000332c:	0001c797          	auipc	a5,0x1c
    80003330:	26c78793          	addi	a5,a5,620 # 8001f598 <bcache+0x8000>
    80003334:	2b87b703          	ld	a4,696(a5)
    80003338:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000333a:	0001c717          	auipc	a4,0x1c
    8000333e:	4c670713          	addi	a4,a4,1222 # 8001f800 <bcache+0x8268>
    80003342:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003344:	2b87b703          	ld	a4,696(a5)
    80003348:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000334a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	24a50513          	addi	a0,a0,586 # 80017598 <bcache>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    panic("brelse");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	1e650513          	addi	a0,a0,486 # 80008550 <syscalls+0x100>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1cc080e7          	jalr	460(ra) # 8000053e <panic>

000000008000337a <bpin>:

void
bpin(struct buf *b) {
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	1000                	addi	s0,sp,32
    80003384:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	21250513          	addi	a0,a0,530 # 80017598 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003396:	40bc                	lw	a5,64(s1)
    80003398:	2785                	addiw	a5,a5,1
    8000339a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	1fc50513          	addi	a0,a0,508 # 80017598 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8e6080e7          	jalr	-1818(ra) # 80000c8a <release>
}
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	64a2                	ld	s1,8(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret

00000000800033b6 <bunpin>:

void
bunpin(struct buf *b) {
    800033b6:	1101                	addi	sp,sp,-32
    800033b8:	ec06                	sd	ra,24(sp)
    800033ba:	e822                	sd	s0,16(sp)
    800033bc:	e426                	sd	s1,8(sp)
    800033be:	1000                	addi	s0,sp,32
    800033c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	1d650513          	addi	a0,a0,470 # 80017598 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	80c080e7          	jalr	-2036(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033d2:	40bc                	lw	a5,64(s1)
    800033d4:	37fd                	addiw	a5,a5,-1
    800033d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d8:	00014517          	auipc	a0,0x14
    800033dc:	1c050513          	addi	a0,a0,448 # 80017598 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	e04a                	sd	s2,0(sp)
    800033fc:	1000                	addi	s0,sp,32
    800033fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003400:	00d5d59b          	srliw	a1,a1,0xd
    80003404:	0001d797          	auipc	a5,0x1d
    80003408:	8707a783          	lw	a5,-1936(a5) # 8001fc74 <sb+0x1c>
    8000340c:	9dbd                	addw	a1,a1,a5
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d9e080e7          	jalr	-610(ra) # 800031ac <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003416:	0074f713          	andi	a4,s1,7
    8000341a:	4785                	li	a5,1
    8000341c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003420:	14ce                	slli	s1,s1,0x33
    80003422:	90d9                	srli	s1,s1,0x36
    80003424:	00950733          	add	a4,a0,s1
    80003428:	05874703          	lbu	a4,88(a4)
    8000342c:	00e7f6b3          	and	a3,a5,a4
    80003430:	c69d                	beqz	a3,8000345e <bfree+0x6c>
    80003432:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003434:	94aa                	add	s1,s1,a0
    80003436:	fff7c793          	not	a5,a5
    8000343a:	8ff9                	and	a5,a5,a4
    8000343c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003440:	00001097          	auipc	ra,0x1
    80003444:	120080e7          	jalr	288(ra) # 80004560 <log_write>
  brelse(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	e92080e7          	jalr	-366(ra) # 800032dc <brelse>
}
    80003452:	60e2                	ld	ra,24(sp)
    80003454:	6442                	ld	s0,16(sp)
    80003456:	64a2                	ld	s1,8(sp)
    80003458:	6902                	ld	s2,0(sp)
    8000345a:	6105                	addi	sp,sp,32
    8000345c:	8082                	ret
    panic("freeing free block");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	0fa50513          	addi	a0,a0,250 # 80008558 <syscalls+0x108>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0d8080e7          	jalr	216(ra) # 8000053e <panic>

000000008000346e <balloc>:
{
    8000346e:	711d                	addi	sp,sp,-96
    80003470:	ec86                	sd	ra,88(sp)
    80003472:	e8a2                	sd	s0,80(sp)
    80003474:	e4a6                	sd	s1,72(sp)
    80003476:	e0ca                	sd	s2,64(sp)
    80003478:	fc4e                	sd	s3,56(sp)
    8000347a:	f852                	sd	s4,48(sp)
    8000347c:	f456                	sd	s5,40(sp)
    8000347e:	f05a                	sd	s6,32(sp)
    80003480:	ec5e                	sd	s7,24(sp)
    80003482:	e862                	sd	s8,16(sp)
    80003484:	e466                	sd	s9,8(sp)
    80003486:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003488:	0001c797          	auipc	a5,0x1c
    8000348c:	7d47a783          	lw	a5,2004(a5) # 8001fc5c <sb+0x4>
    80003490:	10078163          	beqz	a5,80003592 <balloc+0x124>
    80003494:	8baa                	mv	s7,a0
    80003496:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003498:	0001cb17          	auipc	s6,0x1c
    8000349c:	7c0b0b13          	addi	s6,s6,1984 # 8001fc58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034a6:	6c89                	lui	s9,0x2
    800034a8:	a061                	j	80003530 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034aa:	974a                	add	a4,a4,s2
    800034ac:	8fd5                	or	a5,a5,a3
    800034ae:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034b2:	854a                	mv	a0,s2
    800034b4:	00001097          	auipc	ra,0x1
    800034b8:	0ac080e7          	jalr	172(ra) # 80004560 <log_write>
        brelse(bp);
    800034bc:	854a                	mv	a0,s2
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	e1e080e7          	jalr	-482(ra) # 800032dc <brelse>
  bp = bread(dev, bno);
    800034c6:	85a6                	mv	a1,s1
    800034c8:	855e                	mv	a0,s7
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	ce2080e7          	jalr	-798(ra) # 800031ac <bread>
    800034d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034d4:	40000613          	li	a2,1024
    800034d8:	4581                	li	a1,0
    800034da:	05850513          	addi	a0,a0,88
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7f4080e7          	jalr	2036(ra) # 80000cd2 <memset>
  log_write(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	078080e7          	jalr	120(ra) # 80004560 <log_write>
  brelse(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	dea080e7          	jalr	-534(ra) # 800032dc <brelse>
}
    800034fa:	8526                	mv	a0,s1
    800034fc:	60e6                	ld	ra,88(sp)
    800034fe:	6446                	ld	s0,80(sp)
    80003500:	64a6                	ld	s1,72(sp)
    80003502:	6906                	ld	s2,64(sp)
    80003504:	79e2                	ld	s3,56(sp)
    80003506:	7a42                	ld	s4,48(sp)
    80003508:	7aa2                	ld	s5,40(sp)
    8000350a:	7b02                	ld	s6,32(sp)
    8000350c:	6be2                	ld	s7,24(sp)
    8000350e:	6c42                	ld	s8,16(sp)
    80003510:	6ca2                	ld	s9,8(sp)
    80003512:	6125                	addi	sp,sp,96
    80003514:	8082                	ret
    brelse(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	dc4080e7          	jalr	-572(ra) # 800032dc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003520:	015c87bb          	addw	a5,s9,s5
    80003524:	00078a9b          	sext.w	s5,a5
    80003528:	004b2703          	lw	a4,4(s6)
    8000352c:	06eaf363          	bgeu	s5,a4,80003592 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003530:	41fad79b          	sraiw	a5,s5,0x1f
    80003534:	0137d79b          	srliw	a5,a5,0x13
    80003538:	015787bb          	addw	a5,a5,s5
    8000353c:	40d7d79b          	sraiw	a5,a5,0xd
    80003540:	01cb2583          	lw	a1,28(s6)
    80003544:	9dbd                	addw	a1,a1,a5
    80003546:	855e                	mv	a0,s7
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	c64080e7          	jalr	-924(ra) # 800031ac <bread>
    80003550:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003552:	004b2503          	lw	a0,4(s6)
    80003556:	000a849b          	sext.w	s1,s5
    8000355a:	8662                	mv	a2,s8
    8000355c:	faa4fde3          	bgeu	s1,a0,80003516 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003560:	41f6579b          	sraiw	a5,a2,0x1f
    80003564:	01d7d69b          	srliw	a3,a5,0x1d
    80003568:	00c6873b          	addw	a4,a3,a2
    8000356c:	00777793          	andi	a5,a4,7
    80003570:	9f95                	subw	a5,a5,a3
    80003572:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003576:	4037571b          	sraiw	a4,a4,0x3
    8000357a:	00e906b3          	add	a3,s2,a4
    8000357e:	0586c683          	lbu	a3,88(a3)
    80003582:	00d7f5b3          	and	a1,a5,a3
    80003586:	d195                	beqz	a1,800034aa <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003588:	2605                	addiw	a2,a2,1
    8000358a:	2485                	addiw	s1,s1,1
    8000358c:	fd4618e3          	bne	a2,s4,8000355c <balloc+0xee>
    80003590:	b759                	j	80003516 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	fde50513          	addi	a0,a0,-34 # 80008570 <syscalls+0x120>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	fee080e7          	jalr	-18(ra) # 80000588 <printf>
  return 0;
    800035a2:	4481                	li	s1,0
    800035a4:	bf99                	j	800034fa <balloc+0x8c>

00000000800035a6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035a6:	7179                	addi	sp,sp,-48
    800035a8:	f406                	sd	ra,40(sp)
    800035aa:	f022                	sd	s0,32(sp)
    800035ac:	ec26                	sd	s1,24(sp)
    800035ae:	e84a                	sd	s2,16(sp)
    800035b0:	e44e                	sd	s3,8(sp)
    800035b2:	e052                	sd	s4,0(sp)
    800035b4:	1800                	addi	s0,sp,48
    800035b6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035b8:	47ad                	li	a5,11
    800035ba:	02b7e763          	bltu	a5,a1,800035e8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800035be:	02059493          	slli	s1,a1,0x20
    800035c2:	9081                	srli	s1,s1,0x20
    800035c4:	048a                	slli	s1,s1,0x2
    800035c6:	94aa                	add	s1,s1,a0
    800035c8:	0504a903          	lw	s2,80(s1)
    800035cc:	06091e63          	bnez	s2,80003648 <bmap+0xa2>
      addr = balloc(ip->dev);
    800035d0:	4108                	lw	a0,0(a0)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e9c080e7          	jalr	-356(ra) # 8000346e <balloc>
    800035da:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035de:	06090563          	beqz	s2,80003648 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800035e2:	0524a823          	sw	s2,80(s1)
    800035e6:	a08d                	j	80003648 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035e8:	ff45849b          	addiw	s1,a1,-12
    800035ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035f0:	0ff00793          	li	a5,255
    800035f4:	08e7e563          	bltu	a5,a4,8000367e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035f8:	08052903          	lw	s2,128(a0)
    800035fc:	00091d63          	bnez	s2,80003616 <bmap+0x70>
      addr = balloc(ip->dev);
    80003600:	4108                	lw	a0,0(a0)
    80003602:	00000097          	auipc	ra,0x0
    80003606:	e6c080e7          	jalr	-404(ra) # 8000346e <balloc>
    8000360a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000360e:	02090d63          	beqz	s2,80003648 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003612:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003616:	85ca                	mv	a1,s2
    80003618:	0009a503          	lw	a0,0(s3)
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	b90080e7          	jalr	-1136(ra) # 800031ac <bread>
    80003624:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003626:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000362a:	02049593          	slli	a1,s1,0x20
    8000362e:	9181                	srli	a1,a1,0x20
    80003630:	058a                	slli	a1,a1,0x2
    80003632:	00b784b3          	add	s1,a5,a1
    80003636:	0004a903          	lw	s2,0(s1)
    8000363a:	02090063          	beqz	s2,8000365a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000363e:	8552                	mv	a0,s4
    80003640:	00000097          	auipc	ra,0x0
    80003644:	c9c080e7          	jalr	-868(ra) # 800032dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003648:	854a                	mv	a0,s2
    8000364a:	70a2                	ld	ra,40(sp)
    8000364c:	7402                	ld	s0,32(sp)
    8000364e:	64e2                	ld	s1,24(sp)
    80003650:	6942                	ld	s2,16(sp)
    80003652:	69a2                	ld	s3,8(sp)
    80003654:	6a02                	ld	s4,0(sp)
    80003656:	6145                	addi	sp,sp,48
    80003658:	8082                	ret
      addr = balloc(ip->dev);
    8000365a:	0009a503          	lw	a0,0(s3)
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e10080e7          	jalr	-496(ra) # 8000346e <balloc>
    80003666:	0005091b          	sext.w	s2,a0
      if(addr){
    8000366a:	fc090ae3          	beqz	s2,8000363e <bmap+0x98>
        a[bn] = addr;
    8000366e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003672:	8552                	mv	a0,s4
    80003674:	00001097          	auipc	ra,0x1
    80003678:	eec080e7          	jalr	-276(ra) # 80004560 <log_write>
    8000367c:	b7c9                	j	8000363e <bmap+0x98>
  panic("bmap: out of range");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f0a50513          	addi	a0,a0,-246 # 80008588 <syscalls+0x138>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eb8080e7          	jalr	-328(ra) # 8000053e <panic>

000000008000368e <iget>:
{
    8000368e:	7179                	addi	sp,sp,-48
    80003690:	f406                	sd	ra,40(sp)
    80003692:	f022                	sd	s0,32(sp)
    80003694:	ec26                	sd	s1,24(sp)
    80003696:	e84a                	sd	s2,16(sp)
    80003698:	e44e                	sd	s3,8(sp)
    8000369a:	e052                	sd	s4,0(sp)
    8000369c:	1800                	addi	s0,sp,48
    8000369e:	89aa                	mv	s3,a0
    800036a0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036a2:	0001c517          	auipc	a0,0x1c
    800036a6:	5d650513          	addi	a0,a0,1494 # 8001fc78 <itable>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	52c080e7          	jalr	1324(ra) # 80000bd6 <acquire>
  empty = 0;
    800036b2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036b4:	0001c497          	auipc	s1,0x1c
    800036b8:	5dc48493          	addi	s1,s1,1500 # 8001fc90 <itable+0x18>
    800036bc:	0001e697          	auipc	a3,0x1e
    800036c0:	06468693          	addi	a3,a3,100 # 80021720 <log>
    800036c4:	a039                	j	800036d2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c6:	02090b63          	beqz	s2,800036fc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ca:	08848493          	addi	s1,s1,136
    800036ce:	02d48a63          	beq	s1,a3,80003702 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036d2:	449c                	lw	a5,8(s1)
    800036d4:	fef059e3          	blez	a5,800036c6 <iget+0x38>
    800036d8:	4098                	lw	a4,0(s1)
    800036da:	ff3716e3          	bne	a4,s3,800036c6 <iget+0x38>
    800036de:	40d8                	lw	a4,4(s1)
    800036e0:	ff4713e3          	bne	a4,s4,800036c6 <iget+0x38>
      ip->ref++;
    800036e4:	2785                	addiw	a5,a5,1
    800036e6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036e8:	0001c517          	auipc	a0,0x1c
    800036ec:	59050513          	addi	a0,a0,1424 # 8001fc78 <itable>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	59a080e7          	jalr	1434(ra) # 80000c8a <release>
      return ip;
    800036f8:	8926                	mv	s2,s1
    800036fa:	a03d                	j	80003728 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036fc:	f7f9                	bnez	a5,800036ca <iget+0x3c>
    800036fe:	8926                	mv	s2,s1
    80003700:	b7e9                	j	800036ca <iget+0x3c>
  if(empty == 0)
    80003702:	02090c63          	beqz	s2,8000373a <iget+0xac>
  ip->dev = dev;
    80003706:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000370a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000370e:	4785                	li	a5,1
    80003710:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003714:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003718:	0001c517          	auipc	a0,0x1c
    8000371c:	56050513          	addi	a0,a0,1376 # 8001fc78 <itable>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	56a080e7          	jalr	1386(ra) # 80000c8a <release>
}
    80003728:	854a                	mv	a0,s2
    8000372a:	70a2                	ld	ra,40(sp)
    8000372c:	7402                	ld	s0,32(sp)
    8000372e:	64e2                	ld	s1,24(sp)
    80003730:	6942                	ld	s2,16(sp)
    80003732:	69a2                	ld	s3,8(sp)
    80003734:	6a02                	ld	s4,0(sp)
    80003736:	6145                	addi	sp,sp,48
    80003738:	8082                	ret
    panic("iget: no inodes");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	e6650513          	addi	a0,a0,-410 # 800085a0 <syscalls+0x150>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	dfc080e7          	jalr	-516(ra) # 8000053e <panic>

000000008000374a <fsinit>:
fsinit(int dev) {
    8000374a:	7179                	addi	sp,sp,-48
    8000374c:	f406                	sd	ra,40(sp)
    8000374e:	f022                	sd	s0,32(sp)
    80003750:	ec26                	sd	s1,24(sp)
    80003752:	e84a                	sd	s2,16(sp)
    80003754:	e44e                	sd	s3,8(sp)
    80003756:	1800                	addi	s0,sp,48
    80003758:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000375a:	4585                	li	a1,1
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	a50080e7          	jalr	-1456(ra) # 800031ac <bread>
    80003764:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003766:	0001c997          	auipc	s3,0x1c
    8000376a:	4f298993          	addi	s3,s3,1266 # 8001fc58 <sb>
    8000376e:	02000613          	li	a2,32
    80003772:	05850593          	addi	a1,a0,88
    80003776:	854e                	mv	a0,s3
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	5b6080e7          	jalr	1462(ra) # 80000d2e <memmove>
  brelse(bp);
    80003780:	8526                	mv	a0,s1
    80003782:	00000097          	auipc	ra,0x0
    80003786:	b5a080e7          	jalr	-1190(ra) # 800032dc <brelse>
  if(sb.magic != FSMAGIC)
    8000378a:	0009a703          	lw	a4,0(s3)
    8000378e:	102037b7          	lui	a5,0x10203
    80003792:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003796:	02f71263          	bne	a4,a5,800037ba <fsinit+0x70>
  initlog(dev, &sb);
    8000379a:	0001c597          	auipc	a1,0x1c
    8000379e:	4be58593          	addi	a1,a1,1214 # 8001fc58 <sb>
    800037a2:	854a                	mv	a0,s2
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	b40080e7          	jalr	-1216(ra) # 800042e4 <initlog>
}
    800037ac:	70a2                	ld	ra,40(sp)
    800037ae:	7402                	ld	s0,32(sp)
    800037b0:	64e2                	ld	s1,24(sp)
    800037b2:	6942                	ld	s2,16(sp)
    800037b4:	69a2                	ld	s3,8(sp)
    800037b6:	6145                	addi	sp,sp,48
    800037b8:	8082                	ret
    panic("invalid file system");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	df650513          	addi	a0,a0,-522 # 800085b0 <syscalls+0x160>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>

00000000800037ca <iinit>:
{
    800037ca:	7179                	addi	sp,sp,-48
    800037cc:	f406                	sd	ra,40(sp)
    800037ce:	f022                	sd	s0,32(sp)
    800037d0:	ec26                	sd	s1,24(sp)
    800037d2:	e84a                	sd	s2,16(sp)
    800037d4:	e44e                	sd	s3,8(sp)
    800037d6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037d8:	00005597          	auipc	a1,0x5
    800037dc:	df058593          	addi	a1,a1,-528 # 800085c8 <syscalls+0x178>
    800037e0:	0001c517          	auipc	a0,0x1c
    800037e4:	49850513          	addi	a0,a0,1176 # 8001fc78 <itable>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	35e080e7          	jalr	862(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037f0:	0001c497          	auipc	s1,0x1c
    800037f4:	4b048493          	addi	s1,s1,1200 # 8001fca0 <itable+0x28>
    800037f8:	0001e997          	auipc	s3,0x1e
    800037fc:	f3898993          	addi	s3,s3,-200 # 80021730 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003800:	00005917          	auipc	s2,0x5
    80003804:	dd090913          	addi	s2,s2,-560 # 800085d0 <syscalls+0x180>
    80003808:	85ca                	mv	a1,s2
    8000380a:	8526                	mv	a0,s1
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	e3a080e7          	jalr	-454(ra) # 80004646 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003814:	08848493          	addi	s1,s1,136
    80003818:	ff3498e3          	bne	s1,s3,80003808 <iinit+0x3e>
}
    8000381c:	70a2                	ld	ra,40(sp)
    8000381e:	7402                	ld	s0,32(sp)
    80003820:	64e2                	ld	s1,24(sp)
    80003822:	6942                	ld	s2,16(sp)
    80003824:	69a2                	ld	s3,8(sp)
    80003826:	6145                	addi	sp,sp,48
    80003828:	8082                	ret

000000008000382a <ialloc>:
{
    8000382a:	715d                	addi	sp,sp,-80
    8000382c:	e486                	sd	ra,72(sp)
    8000382e:	e0a2                	sd	s0,64(sp)
    80003830:	fc26                	sd	s1,56(sp)
    80003832:	f84a                	sd	s2,48(sp)
    80003834:	f44e                	sd	s3,40(sp)
    80003836:	f052                	sd	s4,32(sp)
    80003838:	ec56                	sd	s5,24(sp)
    8000383a:	e85a                	sd	s6,16(sp)
    8000383c:	e45e                	sd	s7,8(sp)
    8000383e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003840:	0001c717          	auipc	a4,0x1c
    80003844:	42472703          	lw	a4,1060(a4) # 8001fc64 <sb+0xc>
    80003848:	4785                	li	a5,1
    8000384a:	04e7fa63          	bgeu	a5,a4,8000389e <ialloc+0x74>
    8000384e:	8aaa                	mv	s5,a0
    80003850:	8bae                	mv	s7,a1
    80003852:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003854:	0001ca17          	auipc	s4,0x1c
    80003858:	404a0a13          	addi	s4,s4,1028 # 8001fc58 <sb>
    8000385c:	00048b1b          	sext.w	s6,s1
    80003860:	0044d793          	srli	a5,s1,0x4
    80003864:	018a2583          	lw	a1,24(s4)
    80003868:	9dbd                	addw	a1,a1,a5
    8000386a:	8556                	mv	a0,s5
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	940080e7          	jalr	-1728(ra) # 800031ac <bread>
    80003874:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003876:	05850993          	addi	s3,a0,88
    8000387a:	00f4f793          	andi	a5,s1,15
    8000387e:	079a                	slli	a5,a5,0x6
    80003880:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003882:	00099783          	lh	a5,0(s3)
    80003886:	c3a1                	beqz	a5,800038c6 <ialloc+0x9c>
    brelse(bp);
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	a54080e7          	jalr	-1452(ra) # 800032dc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003890:	0485                	addi	s1,s1,1
    80003892:	00ca2703          	lw	a4,12(s4)
    80003896:	0004879b          	sext.w	a5,s1
    8000389a:	fce7e1e3          	bltu	a5,a4,8000385c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000389e:	00005517          	auipc	a0,0x5
    800038a2:	d3a50513          	addi	a0,a0,-710 # 800085d8 <syscalls+0x188>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
  return 0;
    800038ae:	4501                	li	a0,0
}
    800038b0:	60a6                	ld	ra,72(sp)
    800038b2:	6406                	ld	s0,64(sp)
    800038b4:	74e2                	ld	s1,56(sp)
    800038b6:	7942                	ld	s2,48(sp)
    800038b8:	79a2                	ld	s3,40(sp)
    800038ba:	7a02                	ld	s4,32(sp)
    800038bc:	6ae2                	ld	s5,24(sp)
    800038be:	6b42                	ld	s6,16(sp)
    800038c0:	6ba2                	ld	s7,8(sp)
    800038c2:	6161                	addi	sp,sp,80
    800038c4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038c6:	04000613          	li	a2,64
    800038ca:	4581                	li	a1,0
    800038cc:	854e                	mv	a0,s3
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	404080e7          	jalr	1028(ra) # 80000cd2 <memset>
      dip->type = type;
    800038d6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	c84080e7          	jalr	-892(ra) # 80004560 <log_write>
      brelse(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	9f6080e7          	jalr	-1546(ra) # 800032dc <brelse>
      return iget(dev, inum);
    800038ee:	85da                	mv	a1,s6
    800038f0:	8556                	mv	a0,s5
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	d9c080e7          	jalr	-612(ra) # 8000368e <iget>
    800038fa:	bf5d                	j	800038b0 <ialloc+0x86>

00000000800038fc <iupdate>:
{
    800038fc:	1101                	addi	sp,sp,-32
    800038fe:	ec06                	sd	ra,24(sp)
    80003900:	e822                	sd	s0,16(sp)
    80003902:	e426                	sd	s1,8(sp)
    80003904:	e04a                	sd	s2,0(sp)
    80003906:	1000                	addi	s0,sp,32
    80003908:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000390a:	415c                	lw	a5,4(a0)
    8000390c:	0047d79b          	srliw	a5,a5,0x4
    80003910:	0001c597          	auipc	a1,0x1c
    80003914:	3605a583          	lw	a1,864(a1) # 8001fc70 <sb+0x18>
    80003918:	9dbd                	addw	a1,a1,a5
    8000391a:	4108                	lw	a0,0(a0)
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	890080e7          	jalr	-1904(ra) # 800031ac <bread>
    80003924:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003926:	05850793          	addi	a5,a0,88
    8000392a:	40c8                	lw	a0,4(s1)
    8000392c:	893d                	andi	a0,a0,15
    8000392e:	051a                	slli	a0,a0,0x6
    80003930:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003932:	04449703          	lh	a4,68(s1)
    80003936:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000393a:	04649703          	lh	a4,70(s1)
    8000393e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003942:	04849703          	lh	a4,72(s1)
    80003946:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000394a:	04a49703          	lh	a4,74(s1)
    8000394e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003952:	44f8                	lw	a4,76(s1)
    80003954:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003956:	03400613          	li	a2,52
    8000395a:	05048593          	addi	a1,s1,80
    8000395e:	0531                	addi	a0,a0,12
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	3ce080e7          	jalr	974(ra) # 80000d2e <memmove>
  log_write(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	bf6080e7          	jalr	-1034(ra) # 80004560 <log_write>
  brelse(bp);
    80003972:	854a                	mv	a0,s2
    80003974:	00000097          	auipc	ra,0x0
    80003978:	968080e7          	jalr	-1688(ra) # 800032dc <brelse>
}
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6902                	ld	s2,0(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <idup>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	2e450513          	addi	a0,a0,740 # 8001fc78 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	23a080e7          	jalr	570(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039a4:	449c                	lw	a5,8(s1)
    800039a6:	2785                	addiw	a5,a5,1
    800039a8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039aa:	0001c517          	auipc	a0,0x1c
    800039ae:	2ce50513          	addi	a0,a0,718 # 8001fc78 <itable>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	2d8080e7          	jalr	728(ra) # 80000c8a <release>
}
    800039ba:	8526                	mv	a0,s1
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret

00000000800039c6 <ilock>:
{
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	e426                	sd	s1,8(sp)
    800039ce:	e04a                	sd	s2,0(sp)
    800039d0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039d2:	c115                	beqz	a0,800039f6 <ilock+0x30>
    800039d4:	84aa                	mv	s1,a0
    800039d6:	451c                	lw	a5,8(a0)
    800039d8:	00f05f63          	blez	a5,800039f6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039dc:	0541                	addi	a0,a0,16
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	ca2080e7          	jalr	-862(ra) # 80004680 <acquiresleep>
  if(ip->valid == 0){
    800039e6:	40bc                	lw	a5,64(s1)
    800039e8:	cf99                	beqz	a5,80003a06 <ilock+0x40>
}
    800039ea:	60e2                	ld	ra,24(sp)
    800039ec:	6442                	ld	s0,16(sp)
    800039ee:	64a2                	ld	s1,8(sp)
    800039f0:	6902                	ld	s2,0(sp)
    800039f2:	6105                	addi	sp,sp,32
    800039f4:	8082                	ret
    panic("ilock");
    800039f6:	00005517          	auipc	a0,0x5
    800039fa:	bfa50513          	addi	a0,a0,-1030 # 800085f0 <syscalls+0x1a0>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a06:	40dc                	lw	a5,4(s1)
    80003a08:	0047d79b          	srliw	a5,a5,0x4
    80003a0c:	0001c597          	auipc	a1,0x1c
    80003a10:	2645a583          	lw	a1,612(a1) # 8001fc70 <sb+0x18>
    80003a14:	9dbd                	addw	a1,a1,a5
    80003a16:	4088                	lw	a0,0(s1)
    80003a18:	fffff097          	auipc	ra,0xfffff
    80003a1c:	794080e7          	jalr	1940(ra) # 800031ac <bread>
    80003a20:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a22:	05850593          	addi	a1,a0,88
    80003a26:	40dc                	lw	a5,4(s1)
    80003a28:	8bbd                	andi	a5,a5,15
    80003a2a:	079a                	slli	a5,a5,0x6
    80003a2c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a2e:	00059783          	lh	a5,0(a1)
    80003a32:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a36:	00259783          	lh	a5,2(a1)
    80003a3a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a3e:	00459783          	lh	a5,4(a1)
    80003a42:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a46:	00659783          	lh	a5,6(a1)
    80003a4a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a4e:	459c                	lw	a5,8(a1)
    80003a50:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a52:	03400613          	li	a2,52
    80003a56:	05b1                	addi	a1,a1,12
    80003a58:	05048513          	addi	a0,s1,80
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	2d2080e7          	jalr	722(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	876080e7          	jalr	-1930(ra) # 800032dc <brelse>
    ip->valid = 1;
    80003a6e:	4785                	li	a5,1
    80003a70:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a72:	04449783          	lh	a5,68(s1)
    80003a76:	fbb5                	bnez	a5,800039ea <ilock+0x24>
      panic("ilock: no type");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	b8050513          	addi	a0,a0,-1152 # 800085f8 <syscalls+0x1a8>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	abe080e7          	jalr	-1346(ra) # 8000053e <panic>

0000000080003a88 <iunlock>:
{
    80003a88:	1101                	addi	sp,sp,-32
    80003a8a:	ec06                	sd	ra,24(sp)
    80003a8c:	e822                	sd	s0,16(sp)
    80003a8e:	e426                	sd	s1,8(sp)
    80003a90:	e04a                	sd	s2,0(sp)
    80003a92:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a94:	c905                	beqz	a0,80003ac4 <iunlock+0x3c>
    80003a96:	84aa                	mv	s1,a0
    80003a98:	01050913          	addi	s2,a0,16
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00001097          	auipc	ra,0x1
    80003aa2:	c7c080e7          	jalr	-900(ra) # 8000471a <holdingsleep>
    80003aa6:	cd19                	beqz	a0,80003ac4 <iunlock+0x3c>
    80003aa8:	449c                	lw	a5,8(s1)
    80003aaa:	00f05d63          	blez	a5,80003ac4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	00001097          	auipc	ra,0x1
    80003ab4:	c26080e7          	jalr	-986(ra) # 800046d6 <releasesleep>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6902                	ld	s2,0(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret
    panic("iunlock");
    80003ac4:	00005517          	auipc	a0,0x5
    80003ac8:	b4450513          	addi	a0,a0,-1212 # 80008608 <syscalls+0x1b8>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	a72080e7          	jalr	-1422(ra) # 8000053e <panic>

0000000080003ad4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ad4:	7179                	addi	sp,sp,-48
    80003ad6:	f406                	sd	ra,40(sp)
    80003ad8:	f022                	sd	s0,32(sp)
    80003ada:	ec26                	sd	s1,24(sp)
    80003adc:	e84a                	sd	s2,16(sp)
    80003ade:	e44e                	sd	s3,8(sp)
    80003ae0:	e052                	sd	s4,0(sp)
    80003ae2:	1800                	addi	s0,sp,48
    80003ae4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ae6:	05050493          	addi	s1,a0,80
    80003aea:	08050913          	addi	s2,a0,128
    80003aee:	a021                	j	80003af6 <itrunc+0x22>
    80003af0:	0491                	addi	s1,s1,4
    80003af2:	01248d63          	beq	s1,s2,80003b0c <itrunc+0x38>
    if(ip->addrs[i]){
    80003af6:	408c                	lw	a1,0(s1)
    80003af8:	dde5                	beqz	a1,80003af0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003afa:	0009a503          	lw	a0,0(s3)
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	8f4080e7          	jalr	-1804(ra) # 800033f2 <bfree>
      ip->addrs[i] = 0;
    80003b06:	0004a023          	sw	zero,0(s1)
    80003b0a:	b7dd                	j	80003af0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b0c:	0809a583          	lw	a1,128(s3)
    80003b10:	e185                	bnez	a1,80003b30 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b12:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b16:	854e                	mv	a0,s3
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	de4080e7          	jalr	-540(ra) # 800038fc <iupdate>
}
    80003b20:	70a2                	ld	ra,40(sp)
    80003b22:	7402                	ld	s0,32(sp)
    80003b24:	64e2                	ld	s1,24(sp)
    80003b26:	6942                	ld	s2,16(sp)
    80003b28:	69a2                	ld	s3,8(sp)
    80003b2a:	6a02                	ld	s4,0(sp)
    80003b2c:	6145                	addi	sp,sp,48
    80003b2e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b30:	0009a503          	lw	a0,0(s3)
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	678080e7          	jalr	1656(ra) # 800031ac <bread>
    80003b3c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b3e:	05850493          	addi	s1,a0,88
    80003b42:	45850913          	addi	s2,a0,1112
    80003b46:	a021                	j	80003b4e <itrunc+0x7a>
    80003b48:	0491                	addi	s1,s1,4
    80003b4a:	01248b63          	beq	s1,s2,80003b60 <itrunc+0x8c>
      if(a[j])
    80003b4e:	408c                	lw	a1,0(s1)
    80003b50:	dde5                	beqz	a1,80003b48 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b52:	0009a503          	lw	a0,0(s3)
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	89c080e7          	jalr	-1892(ra) # 800033f2 <bfree>
    80003b5e:	b7ed                	j	80003b48 <itrunc+0x74>
    brelse(bp);
    80003b60:	8552                	mv	a0,s4
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	77a080e7          	jalr	1914(ra) # 800032dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b6a:	0809a583          	lw	a1,128(s3)
    80003b6e:	0009a503          	lw	a0,0(s3)
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	880080e7          	jalr	-1920(ra) # 800033f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b7a:	0809a023          	sw	zero,128(s3)
    80003b7e:	bf51                	j	80003b12 <itrunc+0x3e>

0000000080003b80 <iput>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	e04a                	sd	s2,0(sp)
    80003b8a:	1000                	addi	s0,sp,32
    80003b8c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b8e:	0001c517          	auipc	a0,0x1c
    80003b92:	0ea50513          	addi	a0,a0,234 # 8001fc78 <itable>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	040080e7          	jalr	64(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b9e:	4498                	lw	a4,8(s1)
    80003ba0:	4785                	li	a5,1
    80003ba2:	02f70363          	beq	a4,a5,80003bc8 <iput+0x48>
  ip->ref--;
    80003ba6:	449c                	lw	a5,8(s1)
    80003ba8:	37fd                	addiw	a5,a5,-1
    80003baa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bac:	0001c517          	auipc	a0,0x1c
    80003bb0:	0cc50513          	addi	a0,a0,204 # 8001fc78 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	0d6080e7          	jalr	214(ra) # 80000c8a <release>
}
    80003bbc:	60e2                	ld	ra,24(sp)
    80003bbe:	6442                	ld	s0,16(sp)
    80003bc0:	64a2                	ld	s1,8(sp)
    80003bc2:	6902                	ld	s2,0(sp)
    80003bc4:	6105                	addi	sp,sp,32
    80003bc6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc8:	40bc                	lw	a5,64(s1)
    80003bca:	dff1                	beqz	a5,80003ba6 <iput+0x26>
    80003bcc:	04a49783          	lh	a5,74(s1)
    80003bd0:	fbf9                	bnez	a5,80003ba6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bd2:	01048913          	addi	s2,s1,16
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	aa8080e7          	jalr	-1368(ra) # 80004680 <acquiresleep>
    release(&itable.lock);
    80003be0:	0001c517          	auipc	a0,0x1c
    80003be4:	09850513          	addi	a0,a0,152 # 8001fc78 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	0a2080e7          	jalr	162(ra) # 80000c8a <release>
    itrunc(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	ee2080e7          	jalr	-286(ra) # 80003ad4 <itrunc>
    ip->type = 0;
    80003bfa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	cfc080e7          	jalr	-772(ra) # 800038fc <iupdate>
    ip->valid = 0;
    80003c08:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00001097          	auipc	ra,0x1
    80003c12:	ac8080e7          	jalr	-1336(ra) # 800046d6 <releasesleep>
    acquire(&itable.lock);
    80003c16:	0001c517          	auipc	a0,0x1c
    80003c1a:	06250513          	addi	a0,a0,98 # 8001fc78 <itable>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	fb8080e7          	jalr	-72(ra) # 80000bd6 <acquire>
    80003c26:	b741                	j	80003ba6 <iput+0x26>

0000000080003c28 <iunlockput>:
{
    80003c28:	1101                	addi	sp,sp,-32
    80003c2a:	ec06                	sd	ra,24(sp)
    80003c2c:	e822                	sd	s0,16(sp)
    80003c2e:	e426                	sd	s1,8(sp)
    80003c30:	1000                	addi	s0,sp,32
    80003c32:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	e54080e7          	jalr	-428(ra) # 80003a88 <iunlock>
  iput(ip);
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	f42080e7          	jalr	-190(ra) # 80003b80 <iput>
}
    80003c46:	60e2                	ld	ra,24(sp)
    80003c48:	6442                	ld	s0,16(sp)
    80003c4a:	64a2                	ld	s1,8(sp)
    80003c4c:	6105                	addi	sp,sp,32
    80003c4e:	8082                	ret

0000000080003c50 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c50:	1141                	addi	sp,sp,-16
    80003c52:	e422                	sd	s0,8(sp)
    80003c54:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c56:	411c                	lw	a5,0(a0)
    80003c58:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c5a:	415c                	lw	a5,4(a0)
    80003c5c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c5e:	04451783          	lh	a5,68(a0)
    80003c62:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c66:	04a51783          	lh	a5,74(a0)
    80003c6a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c6e:	04c56783          	lwu	a5,76(a0)
    80003c72:	e99c                	sd	a5,16(a1)
}
    80003c74:	6422                	ld	s0,8(sp)
    80003c76:	0141                	addi	sp,sp,16
    80003c78:	8082                	ret

0000000080003c7a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7a:	457c                	lw	a5,76(a0)
    80003c7c:	0ed7e963          	bltu	a5,a3,80003d6e <readi+0xf4>
{
    80003c80:	7159                	addi	sp,sp,-112
    80003c82:	f486                	sd	ra,104(sp)
    80003c84:	f0a2                	sd	s0,96(sp)
    80003c86:	eca6                	sd	s1,88(sp)
    80003c88:	e8ca                	sd	s2,80(sp)
    80003c8a:	e4ce                	sd	s3,72(sp)
    80003c8c:	e0d2                	sd	s4,64(sp)
    80003c8e:	fc56                	sd	s5,56(sp)
    80003c90:	f85a                	sd	s6,48(sp)
    80003c92:	f45e                	sd	s7,40(sp)
    80003c94:	f062                	sd	s8,32(sp)
    80003c96:	ec66                	sd	s9,24(sp)
    80003c98:	e86a                	sd	s10,16(sp)
    80003c9a:	e46e                	sd	s11,8(sp)
    80003c9c:	1880                	addi	s0,sp,112
    80003c9e:	8b2a                	mv	s6,a0
    80003ca0:	8bae                	mv	s7,a1
    80003ca2:	8a32                	mv	s4,a2
    80003ca4:	84b6                	mv	s1,a3
    80003ca6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ca8:	9f35                	addw	a4,a4,a3
    return 0;
    80003caa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cac:	0ad76063          	bltu	a4,a3,80003d4c <readi+0xd2>
  if(off + n > ip->size)
    80003cb0:	00e7f463          	bgeu	a5,a4,80003cb8 <readi+0x3e>
    n = ip->size - off;
    80003cb4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb8:	0a0a8963          	beqz	s5,80003d6a <readi+0xf0>
    80003cbc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbe:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cc2:	5c7d                	li	s8,-1
    80003cc4:	a82d                	j	80003cfe <readi+0x84>
    80003cc6:	020d1d93          	slli	s11,s10,0x20
    80003cca:	020ddd93          	srli	s11,s11,0x20
    80003cce:	05890793          	addi	a5,s2,88
    80003cd2:	86ee                	mv	a3,s11
    80003cd4:	963e                	add	a2,a2,a5
    80003cd6:	85d2                	mv	a1,s4
    80003cd8:	855e                	mv	a0,s7
    80003cda:	ffffe097          	auipc	ra,0xffffe
    80003cde:	7b6080e7          	jalr	1974(ra) # 80002490 <either_copyout>
    80003ce2:	05850d63          	beq	a0,s8,80003d3c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	5f4080e7          	jalr	1524(ra) # 800032dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf0:	013d09bb          	addw	s3,s10,s3
    80003cf4:	009d04bb          	addw	s1,s10,s1
    80003cf8:	9a6e                	add	s4,s4,s11
    80003cfa:	0559f763          	bgeu	s3,s5,80003d48 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cfe:	00a4d59b          	srliw	a1,s1,0xa
    80003d02:	855a                	mv	a0,s6
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	8a2080e7          	jalr	-1886(ra) # 800035a6 <bmap>
    80003d0c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d10:	cd85                	beqz	a1,80003d48 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d12:	000b2503          	lw	a0,0(s6)
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	496080e7          	jalr	1174(ra) # 800031ac <bread>
    80003d1e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d20:	3ff4f613          	andi	a2,s1,1023
    80003d24:	40cc87bb          	subw	a5,s9,a2
    80003d28:	413a873b          	subw	a4,s5,s3
    80003d2c:	8d3e                	mv	s10,a5
    80003d2e:	2781                	sext.w	a5,a5
    80003d30:	0007069b          	sext.w	a3,a4
    80003d34:	f8f6f9e3          	bgeu	a3,a5,80003cc6 <readi+0x4c>
    80003d38:	8d3a                	mv	s10,a4
    80003d3a:	b771                	j	80003cc6 <readi+0x4c>
      brelse(bp);
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	59e080e7          	jalr	1438(ra) # 800032dc <brelse>
      tot = -1;
    80003d46:	59fd                	li	s3,-1
  }
  return tot;
    80003d48:	0009851b          	sext.w	a0,s3
}
    80003d4c:	70a6                	ld	ra,104(sp)
    80003d4e:	7406                	ld	s0,96(sp)
    80003d50:	64e6                	ld	s1,88(sp)
    80003d52:	6946                	ld	s2,80(sp)
    80003d54:	69a6                	ld	s3,72(sp)
    80003d56:	6a06                	ld	s4,64(sp)
    80003d58:	7ae2                	ld	s5,56(sp)
    80003d5a:	7b42                	ld	s6,48(sp)
    80003d5c:	7ba2                	ld	s7,40(sp)
    80003d5e:	7c02                	ld	s8,32(sp)
    80003d60:	6ce2                	ld	s9,24(sp)
    80003d62:	6d42                	ld	s10,16(sp)
    80003d64:	6da2                	ld	s11,8(sp)
    80003d66:	6165                	addi	sp,sp,112
    80003d68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d6a:	89d6                	mv	s3,s5
    80003d6c:	bff1                	j	80003d48 <readi+0xce>
    return 0;
    80003d6e:	4501                	li	a0,0
}
    80003d70:	8082                	ret

0000000080003d72 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d72:	457c                	lw	a5,76(a0)
    80003d74:	10d7e863          	bltu	a5,a3,80003e84 <writei+0x112>
{
    80003d78:	7159                	addi	sp,sp,-112
    80003d7a:	f486                	sd	ra,104(sp)
    80003d7c:	f0a2                	sd	s0,96(sp)
    80003d7e:	eca6                	sd	s1,88(sp)
    80003d80:	e8ca                	sd	s2,80(sp)
    80003d82:	e4ce                	sd	s3,72(sp)
    80003d84:	e0d2                	sd	s4,64(sp)
    80003d86:	fc56                	sd	s5,56(sp)
    80003d88:	f85a                	sd	s6,48(sp)
    80003d8a:	f45e                	sd	s7,40(sp)
    80003d8c:	f062                	sd	s8,32(sp)
    80003d8e:	ec66                	sd	s9,24(sp)
    80003d90:	e86a                	sd	s10,16(sp)
    80003d92:	e46e                	sd	s11,8(sp)
    80003d94:	1880                	addi	s0,sp,112
    80003d96:	8aaa                	mv	s5,a0
    80003d98:	8bae                	mv	s7,a1
    80003d9a:	8a32                	mv	s4,a2
    80003d9c:	8936                	mv	s2,a3
    80003d9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003da0:	00e687bb          	addw	a5,a3,a4
    80003da4:	0ed7e263          	bltu	a5,a3,80003e88 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003da8:	00043737          	lui	a4,0x43
    80003dac:	0ef76063          	bltu	a4,a5,80003e8c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db0:	0c0b0863          	beqz	s6,80003e80 <writei+0x10e>
    80003db4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dba:	5c7d                	li	s8,-1
    80003dbc:	a091                	j	80003e00 <writei+0x8e>
    80003dbe:	020d1d93          	slli	s11,s10,0x20
    80003dc2:	020ddd93          	srli	s11,s11,0x20
    80003dc6:	05848793          	addi	a5,s1,88
    80003dca:	86ee                	mv	a3,s11
    80003dcc:	8652                	mv	a2,s4
    80003dce:	85de                	mv	a1,s7
    80003dd0:	953e                	add	a0,a0,a5
    80003dd2:	ffffe097          	auipc	ra,0xffffe
    80003dd6:	714080e7          	jalr	1812(ra) # 800024e6 <either_copyin>
    80003dda:	07850263          	beq	a0,s8,80003e3e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dde:	8526                	mv	a0,s1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	780080e7          	jalr	1920(ra) # 80004560 <log_write>
    brelse(bp);
    80003de8:	8526                	mv	a0,s1
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	4f2080e7          	jalr	1266(ra) # 800032dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df2:	013d09bb          	addw	s3,s10,s3
    80003df6:	012d093b          	addw	s2,s10,s2
    80003dfa:	9a6e                	add	s4,s4,s11
    80003dfc:	0569f663          	bgeu	s3,s6,80003e48 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e00:	00a9559b          	srliw	a1,s2,0xa
    80003e04:	8556                	mv	a0,s5
    80003e06:	fffff097          	auipc	ra,0xfffff
    80003e0a:	7a0080e7          	jalr	1952(ra) # 800035a6 <bmap>
    80003e0e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e12:	c99d                	beqz	a1,80003e48 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e14:	000aa503          	lw	a0,0(s5)
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	394080e7          	jalr	916(ra) # 800031ac <bread>
    80003e20:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e22:	3ff97513          	andi	a0,s2,1023
    80003e26:	40ac87bb          	subw	a5,s9,a0
    80003e2a:	413b073b          	subw	a4,s6,s3
    80003e2e:	8d3e                	mv	s10,a5
    80003e30:	2781                	sext.w	a5,a5
    80003e32:	0007069b          	sext.w	a3,a4
    80003e36:	f8f6f4e3          	bgeu	a3,a5,80003dbe <writei+0x4c>
    80003e3a:	8d3a                	mv	s10,a4
    80003e3c:	b749                	j	80003dbe <writei+0x4c>
      brelse(bp);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	49c080e7          	jalr	1180(ra) # 800032dc <brelse>
  }

  if(off > ip->size)
    80003e48:	04caa783          	lw	a5,76(s5)
    80003e4c:	0127f463          	bgeu	a5,s2,80003e54 <writei+0xe2>
    ip->size = off;
    80003e50:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e54:	8556                	mv	a0,s5
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	aa6080e7          	jalr	-1370(ra) # 800038fc <iupdate>

  return tot;
    80003e5e:	0009851b          	sext.w	a0,s3
}
    80003e62:	70a6                	ld	ra,104(sp)
    80003e64:	7406                	ld	s0,96(sp)
    80003e66:	64e6                	ld	s1,88(sp)
    80003e68:	6946                	ld	s2,80(sp)
    80003e6a:	69a6                	ld	s3,72(sp)
    80003e6c:	6a06                	ld	s4,64(sp)
    80003e6e:	7ae2                	ld	s5,56(sp)
    80003e70:	7b42                	ld	s6,48(sp)
    80003e72:	7ba2                	ld	s7,40(sp)
    80003e74:	7c02                	ld	s8,32(sp)
    80003e76:	6ce2                	ld	s9,24(sp)
    80003e78:	6d42                	ld	s10,16(sp)
    80003e7a:	6da2                	ld	s11,8(sp)
    80003e7c:	6165                	addi	sp,sp,112
    80003e7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e80:	89da                	mv	s3,s6
    80003e82:	bfc9                	j	80003e54 <writei+0xe2>
    return -1;
    80003e84:	557d                	li	a0,-1
}
    80003e86:	8082                	ret
    return -1;
    80003e88:	557d                	li	a0,-1
    80003e8a:	bfe1                	j	80003e62 <writei+0xf0>
    return -1;
    80003e8c:	557d                	li	a0,-1
    80003e8e:	bfd1                	j	80003e62 <writei+0xf0>

0000000080003e90 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e90:	1141                	addi	sp,sp,-16
    80003e92:	e406                	sd	ra,8(sp)
    80003e94:	e022                	sd	s0,0(sp)
    80003e96:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e98:	4639                	li	a2,14
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	f08080e7          	jalr	-248(ra) # 80000da2 <strncmp>
}
    80003ea2:	60a2                	ld	ra,8(sp)
    80003ea4:	6402                	ld	s0,0(sp)
    80003ea6:	0141                	addi	sp,sp,16
    80003ea8:	8082                	ret

0000000080003eaa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eba:	04451703          	lh	a4,68(a0)
    80003ebe:	4785                	li	a5,1
    80003ec0:	00f71a63          	bne	a4,a5,80003ed4 <dirlookup+0x2a>
    80003ec4:	892a                	mv	s2,a0
    80003ec6:	89ae                	mv	s3,a1
    80003ec8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	457c                	lw	a5,76(a0)
    80003ecc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ece:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed0:	e79d                	bnez	a5,80003efe <dirlookup+0x54>
    80003ed2:	a8a5                	j	80003f4a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ed4:	00004517          	auipc	a0,0x4
    80003ed8:	73c50513          	addi	a0,a0,1852 # 80008610 <syscalls+0x1c0>
    80003edc:	ffffc097          	auipc	ra,0xffffc
    80003ee0:	662080e7          	jalr	1634(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ee4:	00004517          	auipc	a0,0x4
    80003ee8:	74450513          	addi	a0,a0,1860 # 80008628 <syscalls+0x1d8>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	652080e7          	jalr	1618(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	04f4f763          	bgeu	s1,a5,80003f48 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efe:	4741                	li	a4,16
    80003f00:	86a6                	mv	a3,s1
    80003f02:	fc040613          	addi	a2,s0,-64
    80003f06:	4581                	li	a1,0
    80003f08:	854a                	mv	a0,s2
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	d70080e7          	jalr	-656(ra) # 80003c7a <readi>
    80003f12:	47c1                	li	a5,16
    80003f14:	fcf518e3          	bne	a0,a5,80003ee4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f18:	fc045783          	lhu	a5,-64(s0)
    80003f1c:	dfe1                	beqz	a5,80003ef4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f1e:	fc240593          	addi	a1,s0,-62
    80003f22:	854e                	mv	a0,s3
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	f6c080e7          	jalr	-148(ra) # 80003e90 <namecmp>
    80003f2c:	f561                	bnez	a0,80003ef4 <dirlookup+0x4a>
      if(poff)
    80003f2e:	000a0463          	beqz	s4,80003f36 <dirlookup+0x8c>
        *poff = off;
    80003f32:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f36:	fc045583          	lhu	a1,-64(s0)
    80003f3a:	00092503          	lw	a0,0(s2)
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	750080e7          	jalr	1872(ra) # 8000368e <iget>
    80003f46:	a011                	j	80003f4a <dirlookup+0xa0>
  return 0;
    80003f48:	4501                	li	a0,0
}
    80003f4a:	70e2                	ld	ra,56(sp)
    80003f4c:	7442                	ld	s0,48(sp)
    80003f4e:	74a2                	ld	s1,40(sp)
    80003f50:	7902                	ld	s2,32(sp)
    80003f52:	69e2                	ld	s3,24(sp)
    80003f54:	6a42                	ld	s4,16(sp)
    80003f56:	6121                	addi	sp,sp,64
    80003f58:	8082                	ret

0000000080003f5a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f5a:	711d                	addi	sp,sp,-96
    80003f5c:	ec86                	sd	ra,88(sp)
    80003f5e:	e8a2                	sd	s0,80(sp)
    80003f60:	e4a6                	sd	s1,72(sp)
    80003f62:	e0ca                	sd	s2,64(sp)
    80003f64:	fc4e                	sd	s3,56(sp)
    80003f66:	f852                	sd	s4,48(sp)
    80003f68:	f456                	sd	s5,40(sp)
    80003f6a:	f05a                	sd	s6,32(sp)
    80003f6c:	ec5e                	sd	s7,24(sp)
    80003f6e:	e862                	sd	s8,16(sp)
    80003f70:	e466                	sd	s9,8(sp)
    80003f72:	1080                	addi	s0,sp,96
    80003f74:	84aa                	mv	s1,a0
    80003f76:	8aae                	mv	s5,a1
    80003f78:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f7a:	00054703          	lbu	a4,0(a0)
    80003f7e:	02f00793          	li	a5,47
    80003f82:	02f70363          	beq	a4,a5,80003fa8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f86:	ffffe097          	auipc	ra,0xffffe
    80003f8a:	a26080e7          	jalr	-1498(ra) # 800019ac <myproc>
    80003f8e:	17053503          	ld	a0,368(a0)
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	9f6080e7          	jalr	-1546(ra) # 80003988 <idup>
    80003f9a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f9c:	02f00913          	li	s2,47
  len = path - s;
    80003fa0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fa2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fa4:	4b85                	li	s7,1
    80003fa6:	a865                	j	8000405e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fa8:	4585                	li	a1,1
    80003faa:	4505                	li	a0,1
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	6e2080e7          	jalr	1762(ra) # 8000368e <iget>
    80003fb4:	89aa                	mv	s3,a0
    80003fb6:	b7dd                	j	80003f9c <namex+0x42>
      iunlockput(ip);
    80003fb8:	854e                	mv	a0,s3
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	c6e080e7          	jalr	-914(ra) # 80003c28 <iunlockput>
      return 0;
    80003fc2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fc4:	854e                	mv	a0,s3
    80003fc6:	60e6                	ld	ra,88(sp)
    80003fc8:	6446                	ld	s0,80(sp)
    80003fca:	64a6                	ld	s1,72(sp)
    80003fcc:	6906                	ld	s2,64(sp)
    80003fce:	79e2                	ld	s3,56(sp)
    80003fd0:	7a42                	ld	s4,48(sp)
    80003fd2:	7aa2                	ld	s5,40(sp)
    80003fd4:	7b02                	ld	s6,32(sp)
    80003fd6:	6be2                	ld	s7,24(sp)
    80003fd8:	6c42                	ld	s8,16(sp)
    80003fda:	6ca2                	ld	s9,8(sp)
    80003fdc:	6125                	addi	sp,sp,96
    80003fde:	8082                	ret
      iunlock(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	aa6080e7          	jalr	-1370(ra) # 80003a88 <iunlock>
      return ip;
    80003fea:	bfe9                	j	80003fc4 <namex+0x6a>
      iunlockput(ip);
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	c3a080e7          	jalr	-966(ra) # 80003c28 <iunlockput>
      return 0;
    80003ff6:	89e6                	mv	s3,s9
    80003ff8:	b7f1                	j	80003fc4 <namex+0x6a>
  len = path - s;
    80003ffa:	40b48633          	sub	a2,s1,a1
    80003ffe:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004002:	099c5463          	bge	s8,s9,8000408a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004006:	4639                	li	a2,14
    80004008:	8552                	mv	a0,s4
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	d24080e7          	jalr	-732(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	01279763          	bne	a5,s2,80004024 <namex+0xca>
    path++;
    8000401a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	ff278de3          	beq	a5,s2,8000401a <namex+0xc0>
    ilock(ip);
    80004024:	854e                	mv	a0,s3
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	9a0080e7          	jalr	-1632(ra) # 800039c6 <ilock>
    if(ip->type != T_DIR){
    8000402e:	04499783          	lh	a5,68(s3)
    80004032:	f97793e3          	bne	a5,s7,80003fb8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004036:	000a8563          	beqz	s5,80004040 <namex+0xe6>
    8000403a:	0004c783          	lbu	a5,0(s1)
    8000403e:	d3cd                	beqz	a5,80003fe0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004040:	865a                	mv	a2,s6
    80004042:	85d2                	mv	a1,s4
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	e64080e7          	jalr	-412(ra) # 80003eaa <dirlookup>
    8000404e:	8caa                	mv	s9,a0
    80004050:	dd51                	beqz	a0,80003fec <namex+0x92>
    iunlockput(ip);
    80004052:	854e                	mv	a0,s3
    80004054:	00000097          	auipc	ra,0x0
    80004058:	bd4080e7          	jalr	-1068(ra) # 80003c28 <iunlockput>
    ip = next;
    8000405c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000405e:	0004c783          	lbu	a5,0(s1)
    80004062:	05279763          	bne	a5,s2,800040b0 <namex+0x156>
    path++;
    80004066:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004068:	0004c783          	lbu	a5,0(s1)
    8000406c:	ff278de3          	beq	a5,s2,80004066 <namex+0x10c>
  if(*path == 0)
    80004070:	c79d                	beqz	a5,8000409e <namex+0x144>
    path++;
    80004072:	85a6                	mv	a1,s1
  len = path - s;
    80004074:	8cda                	mv	s9,s6
    80004076:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004078:	01278963          	beq	a5,s2,8000408a <namex+0x130>
    8000407c:	dfbd                	beqz	a5,80003ffa <namex+0xa0>
    path++;
    8000407e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004080:	0004c783          	lbu	a5,0(s1)
    80004084:	ff279ce3          	bne	a5,s2,8000407c <namex+0x122>
    80004088:	bf8d                	j	80003ffa <namex+0xa0>
    memmove(name, s, len);
    8000408a:	2601                	sext.w	a2,a2
    8000408c:	8552                	mv	a0,s4
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	ca0080e7          	jalr	-864(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004096:	9cd2                	add	s9,s9,s4
    80004098:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000409c:	bf9d                	j	80004012 <namex+0xb8>
  if(nameiparent){
    8000409e:	f20a83e3          	beqz	s5,80003fc4 <namex+0x6a>
    iput(ip);
    800040a2:	854e                	mv	a0,s3
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	adc080e7          	jalr	-1316(ra) # 80003b80 <iput>
    return 0;
    800040ac:	4981                	li	s3,0
    800040ae:	bf19                	j	80003fc4 <namex+0x6a>
  if(*path == 0)
    800040b0:	d7fd                	beqz	a5,8000409e <namex+0x144>
  while(*path != '/' && *path != 0)
    800040b2:	0004c783          	lbu	a5,0(s1)
    800040b6:	85a6                	mv	a1,s1
    800040b8:	b7d1                	j	8000407c <namex+0x122>

00000000800040ba <dirlink>:
{
    800040ba:	7139                	addi	sp,sp,-64
    800040bc:	fc06                	sd	ra,56(sp)
    800040be:	f822                	sd	s0,48(sp)
    800040c0:	f426                	sd	s1,40(sp)
    800040c2:	f04a                	sd	s2,32(sp)
    800040c4:	ec4e                	sd	s3,24(sp)
    800040c6:	e852                	sd	s4,16(sp)
    800040c8:	0080                	addi	s0,sp,64
    800040ca:	892a                	mv	s2,a0
    800040cc:	8a2e                	mv	s4,a1
    800040ce:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040d0:	4601                	li	a2,0
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	dd8080e7          	jalr	-552(ra) # 80003eaa <dirlookup>
    800040da:	e93d                	bnez	a0,80004150 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040dc:	04c92483          	lw	s1,76(s2)
    800040e0:	c49d                	beqz	s1,8000410e <dirlink+0x54>
    800040e2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e4:	4741                	li	a4,16
    800040e6:	86a6                	mv	a3,s1
    800040e8:	fc040613          	addi	a2,s0,-64
    800040ec:	4581                	li	a1,0
    800040ee:	854a                	mv	a0,s2
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	b8a080e7          	jalr	-1142(ra) # 80003c7a <readi>
    800040f8:	47c1                	li	a5,16
    800040fa:	06f51163          	bne	a0,a5,8000415c <dirlink+0xa2>
    if(de.inum == 0)
    800040fe:	fc045783          	lhu	a5,-64(s0)
    80004102:	c791                	beqz	a5,8000410e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004104:	24c1                	addiw	s1,s1,16
    80004106:	04c92783          	lw	a5,76(s2)
    8000410a:	fcf4ede3          	bltu	s1,a5,800040e4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000410e:	4639                	li	a2,14
    80004110:	85d2                	mv	a1,s4
    80004112:	fc240513          	addi	a0,s0,-62
    80004116:	ffffd097          	auipc	ra,0xffffd
    8000411a:	cc8080e7          	jalr	-824(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000411e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004122:	4741                	li	a4,16
    80004124:	86a6                	mv	a3,s1
    80004126:	fc040613          	addi	a2,s0,-64
    8000412a:	4581                	li	a1,0
    8000412c:	854a                	mv	a0,s2
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	c44080e7          	jalr	-956(ra) # 80003d72 <writei>
    80004136:	1541                	addi	a0,a0,-16
    80004138:	00a03533          	snez	a0,a0
    8000413c:	40a00533          	neg	a0,a0
}
    80004140:	70e2                	ld	ra,56(sp)
    80004142:	7442                	ld	s0,48(sp)
    80004144:	74a2                	ld	s1,40(sp)
    80004146:	7902                	ld	s2,32(sp)
    80004148:	69e2                	ld	s3,24(sp)
    8000414a:	6a42                	ld	s4,16(sp)
    8000414c:	6121                	addi	sp,sp,64
    8000414e:	8082                	ret
    iput(ip);
    80004150:	00000097          	auipc	ra,0x0
    80004154:	a30080e7          	jalr	-1488(ra) # 80003b80 <iput>
    return -1;
    80004158:	557d                	li	a0,-1
    8000415a:	b7dd                	j	80004140 <dirlink+0x86>
      panic("dirlink read");
    8000415c:	00004517          	auipc	a0,0x4
    80004160:	4dc50513          	addi	a0,a0,1244 # 80008638 <syscalls+0x1e8>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	3da080e7          	jalr	986(ra) # 8000053e <panic>

000000008000416c <namei>:

struct inode*
namei(char *path)
{
    8000416c:	1101                	addi	sp,sp,-32
    8000416e:	ec06                	sd	ra,24(sp)
    80004170:	e822                	sd	s0,16(sp)
    80004172:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004174:	fe040613          	addi	a2,s0,-32
    80004178:	4581                	li	a1,0
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	de0080e7          	jalr	-544(ra) # 80003f5a <namex>
}
    80004182:	60e2                	ld	ra,24(sp)
    80004184:	6442                	ld	s0,16(sp)
    80004186:	6105                	addi	sp,sp,32
    80004188:	8082                	ret

000000008000418a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000418a:	1141                	addi	sp,sp,-16
    8000418c:	e406                	sd	ra,8(sp)
    8000418e:	e022                	sd	s0,0(sp)
    80004190:	0800                	addi	s0,sp,16
    80004192:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004194:	4585                	li	a1,1
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	dc4080e7          	jalr	-572(ra) # 80003f5a <namex>
}
    8000419e:	60a2                	ld	ra,8(sp)
    800041a0:	6402                	ld	s0,0(sp)
    800041a2:	0141                	addi	sp,sp,16
    800041a4:	8082                	ret

00000000800041a6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041a6:	1101                	addi	sp,sp,-32
    800041a8:	ec06                	sd	ra,24(sp)
    800041aa:	e822                	sd	s0,16(sp)
    800041ac:	e426                	sd	s1,8(sp)
    800041ae:	e04a                	sd	s2,0(sp)
    800041b0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041b2:	0001d917          	auipc	s2,0x1d
    800041b6:	56e90913          	addi	s2,s2,1390 # 80021720 <log>
    800041ba:	01892583          	lw	a1,24(s2)
    800041be:	02892503          	lw	a0,40(s2)
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	fea080e7          	jalr	-22(ra) # 800031ac <bread>
    800041ca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041cc:	02c92683          	lw	a3,44(s2)
    800041d0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041d2:	02d05763          	blez	a3,80004200 <write_head+0x5a>
    800041d6:	0001d797          	auipc	a5,0x1d
    800041da:	57a78793          	addi	a5,a5,1402 # 80021750 <log+0x30>
    800041de:	05c50713          	addi	a4,a0,92
    800041e2:	36fd                	addiw	a3,a3,-1
    800041e4:	1682                	slli	a3,a3,0x20
    800041e6:	9281                	srli	a3,a3,0x20
    800041e8:	068a                	slli	a3,a3,0x2
    800041ea:	0001d617          	auipc	a2,0x1d
    800041ee:	56a60613          	addi	a2,a2,1386 # 80021754 <log+0x34>
    800041f2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041f4:	4390                	lw	a2,0(a5)
    800041f6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041f8:	0791                	addi	a5,a5,4
    800041fa:	0711                	addi	a4,a4,4
    800041fc:	fed79ce3          	bne	a5,a3,800041f4 <write_head+0x4e>
  }
  bwrite(buf);
    80004200:	8526                	mv	a0,s1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	09c080e7          	jalr	156(ra) # 8000329e <bwrite>
  brelse(buf);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	0d0080e7          	jalr	208(ra) # 800032dc <brelse>
}
    80004214:	60e2                	ld	ra,24(sp)
    80004216:	6442                	ld	s0,16(sp)
    80004218:	64a2                	ld	s1,8(sp)
    8000421a:	6902                	ld	s2,0(sp)
    8000421c:	6105                	addi	sp,sp,32
    8000421e:	8082                	ret

0000000080004220 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004220:	0001d797          	auipc	a5,0x1d
    80004224:	52c7a783          	lw	a5,1324(a5) # 8002174c <log+0x2c>
    80004228:	0af05d63          	blez	a5,800042e2 <install_trans+0xc2>
{
    8000422c:	7139                	addi	sp,sp,-64
    8000422e:	fc06                	sd	ra,56(sp)
    80004230:	f822                	sd	s0,48(sp)
    80004232:	f426                	sd	s1,40(sp)
    80004234:	f04a                	sd	s2,32(sp)
    80004236:	ec4e                	sd	s3,24(sp)
    80004238:	e852                	sd	s4,16(sp)
    8000423a:	e456                	sd	s5,8(sp)
    8000423c:	e05a                	sd	s6,0(sp)
    8000423e:	0080                	addi	s0,sp,64
    80004240:	8b2a                	mv	s6,a0
    80004242:	0001da97          	auipc	s5,0x1d
    80004246:	50ea8a93          	addi	s5,s5,1294 # 80021750 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000424c:	0001d997          	auipc	s3,0x1d
    80004250:	4d498993          	addi	s3,s3,1236 # 80021720 <log>
    80004254:	a00d                	j	80004276 <install_trans+0x56>
    brelse(lbuf);
    80004256:	854a                	mv	a0,s2
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	084080e7          	jalr	132(ra) # 800032dc <brelse>
    brelse(dbuf);
    80004260:	8526                	mv	a0,s1
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	07a080e7          	jalr	122(ra) # 800032dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426a:	2a05                	addiw	s4,s4,1
    8000426c:	0a91                	addi	s5,s5,4
    8000426e:	02c9a783          	lw	a5,44(s3)
    80004272:	04fa5e63          	bge	s4,a5,800042ce <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004276:	0189a583          	lw	a1,24(s3)
    8000427a:	014585bb          	addw	a1,a1,s4
    8000427e:	2585                	addiw	a1,a1,1
    80004280:	0289a503          	lw	a0,40(s3)
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	f28080e7          	jalr	-216(ra) # 800031ac <bread>
    8000428c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000428e:	000aa583          	lw	a1,0(s5)
    80004292:	0289a503          	lw	a0,40(s3)
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	f16080e7          	jalr	-234(ra) # 800031ac <bread>
    8000429e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042a0:	40000613          	li	a2,1024
    800042a4:	05890593          	addi	a1,s2,88
    800042a8:	05850513          	addi	a0,a0,88
    800042ac:	ffffd097          	auipc	ra,0xffffd
    800042b0:	a82080e7          	jalr	-1406(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042b4:	8526                	mv	a0,s1
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	fe8080e7          	jalr	-24(ra) # 8000329e <bwrite>
    if(recovering == 0)
    800042be:	f80b1ce3          	bnez	s6,80004256 <install_trans+0x36>
      bunpin(dbuf);
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	0f2080e7          	jalr	242(ra) # 800033b6 <bunpin>
    800042cc:	b769                	j	80004256 <install_trans+0x36>
}
    800042ce:	70e2                	ld	ra,56(sp)
    800042d0:	7442                	ld	s0,48(sp)
    800042d2:	74a2                	ld	s1,40(sp)
    800042d4:	7902                	ld	s2,32(sp)
    800042d6:	69e2                	ld	s3,24(sp)
    800042d8:	6a42                	ld	s4,16(sp)
    800042da:	6aa2                	ld	s5,8(sp)
    800042dc:	6b02                	ld	s6,0(sp)
    800042de:	6121                	addi	sp,sp,64
    800042e0:	8082                	ret
    800042e2:	8082                	ret

00000000800042e4 <initlog>:
{
    800042e4:	7179                	addi	sp,sp,-48
    800042e6:	f406                	sd	ra,40(sp)
    800042e8:	f022                	sd	s0,32(sp)
    800042ea:	ec26                	sd	s1,24(sp)
    800042ec:	e84a                	sd	s2,16(sp)
    800042ee:	e44e                	sd	s3,8(sp)
    800042f0:	1800                	addi	s0,sp,48
    800042f2:	892a                	mv	s2,a0
    800042f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042f6:	0001d497          	auipc	s1,0x1d
    800042fa:	42a48493          	addi	s1,s1,1066 # 80021720 <log>
    800042fe:	00004597          	auipc	a1,0x4
    80004302:	34a58593          	addi	a1,a1,842 # 80008648 <syscalls+0x1f8>
    80004306:	8526                	mv	a0,s1
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	83e080e7          	jalr	-1986(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004310:	0149a583          	lw	a1,20(s3)
    80004314:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004316:	0109a783          	lw	a5,16(s3)
    8000431a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000431c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004320:	854a                	mv	a0,s2
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	e8a080e7          	jalr	-374(ra) # 800031ac <bread>
  log.lh.n = lh->n;
    8000432a:	4d34                	lw	a3,88(a0)
    8000432c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	02d05563          	blez	a3,80004358 <initlog+0x74>
    80004332:	05c50793          	addi	a5,a0,92
    80004336:	0001d717          	auipc	a4,0x1d
    8000433a:	41a70713          	addi	a4,a4,1050 # 80021750 <log+0x30>
    8000433e:	36fd                	addiw	a3,a3,-1
    80004340:	1682                	slli	a3,a3,0x20
    80004342:	9281                	srli	a3,a3,0x20
    80004344:	068a                	slli	a3,a3,0x2
    80004346:	06050613          	addi	a2,a0,96
    8000434a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000434c:	4390                	lw	a2,0(a5)
    8000434e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004350:	0791                	addi	a5,a5,4
    80004352:	0711                	addi	a4,a4,4
    80004354:	fed79ce3          	bne	a5,a3,8000434c <initlog+0x68>
  brelse(buf);
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	f84080e7          	jalr	-124(ra) # 800032dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004360:	4505                	li	a0,1
    80004362:	00000097          	auipc	ra,0x0
    80004366:	ebe080e7          	jalr	-322(ra) # 80004220 <install_trans>
  log.lh.n = 0;
    8000436a:	0001d797          	auipc	a5,0x1d
    8000436e:	3e07a123          	sw	zero,994(a5) # 8002174c <log+0x2c>
  write_head(); // clear the log
    80004372:	00000097          	auipc	ra,0x0
    80004376:	e34080e7          	jalr	-460(ra) # 800041a6 <write_head>
}
    8000437a:	70a2                	ld	ra,40(sp)
    8000437c:	7402                	ld	s0,32(sp)
    8000437e:	64e2                	ld	s1,24(sp)
    80004380:	6942                	ld	s2,16(sp)
    80004382:	69a2                	ld	s3,8(sp)
    80004384:	6145                	addi	sp,sp,48
    80004386:	8082                	ret

0000000080004388 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004388:	1101                	addi	sp,sp,-32
    8000438a:	ec06                	sd	ra,24(sp)
    8000438c:	e822                	sd	s0,16(sp)
    8000438e:	e426                	sd	s1,8(sp)
    80004390:	e04a                	sd	s2,0(sp)
    80004392:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004394:	0001d517          	auipc	a0,0x1d
    80004398:	38c50513          	addi	a0,a0,908 # 80021720 <log>
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043a4:	0001d497          	auipc	s1,0x1d
    800043a8:	37c48493          	addi	s1,s1,892 # 80021720 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ac:	4979                	li	s2,30
    800043ae:	a039                	j	800043bc <begin_op+0x34>
      sleep(&log, &log.lock);
    800043b0:	85a6                	mv	a1,s1
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffe097          	auipc	ra,0xffffe
    800043b8:	cc8080e7          	jalr	-824(ra) # 8000207c <sleep>
    if(log.committing){
    800043bc:	50dc                	lw	a5,36(s1)
    800043be:	fbed                	bnez	a5,800043b0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043c0:	509c                	lw	a5,32(s1)
    800043c2:	0017871b          	addiw	a4,a5,1
    800043c6:	0007069b          	sext.w	a3,a4
    800043ca:	0027179b          	slliw	a5,a4,0x2
    800043ce:	9fb9                	addw	a5,a5,a4
    800043d0:	0017979b          	slliw	a5,a5,0x1
    800043d4:	54d8                	lw	a4,44(s1)
    800043d6:	9fb9                	addw	a5,a5,a4
    800043d8:	00f95963          	bge	s2,a5,800043ea <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043dc:	85a6                	mv	a1,s1
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffe097          	auipc	ra,0xffffe
    800043e4:	c9c080e7          	jalr	-868(ra) # 8000207c <sleep>
    800043e8:	bfd1                	j	800043bc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043ea:	0001d517          	auipc	a0,0x1d
    800043ee:	33650513          	addi	a0,a0,822 # 80021720 <log>
    800043f2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	896080e7          	jalr	-1898(ra) # 80000c8a <release>
      break;
    }
  }
}
    800043fc:	60e2                	ld	ra,24(sp)
    800043fe:	6442                	ld	s0,16(sp)
    80004400:	64a2                	ld	s1,8(sp)
    80004402:	6902                	ld	s2,0(sp)
    80004404:	6105                	addi	sp,sp,32
    80004406:	8082                	ret

0000000080004408 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004408:	7139                	addi	sp,sp,-64
    8000440a:	fc06                	sd	ra,56(sp)
    8000440c:	f822                	sd	s0,48(sp)
    8000440e:	f426                	sd	s1,40(sp)
    80004410:	f04a                	sd	s2,32(sp)
    80004412:	ec4e                	sd	s3,24(sp)
    80004414:	e852                	sd	s4,16(sp)
    80004416:	e456                	sd	s5,8(sp)
    80004418:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000441a:	0001d497          	auipc	s1,0x1d
    8000441e:	30648493          	addi	s1,s1,774 # 80021720 <log>
    80004422:	8526                	mv	a0,s1
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7b2080e7          	jalr	1970(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000442c:	509c                	lw	a5,32(s1)
    8000442e:	37fd                	addiw	a5,a5,-1
    80004430:	0007891b          	sext.w	s2,a5
    80004434:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004436:	50dc                	lw	a5,36(s1)
    80004438:	e7b9                	bnez	a5,80004486 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000443a:	04091e63          	bnez	s2,80004496 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000443e:	0001d497          	auipc	s1,0x1d
    80004442:	2e248493          	addi	s1,s1,738 # 80021720 <log>
    80004446:	4785                	li	a5,1
    80004448:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000444a:	8526                	mv	a0,s1
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004454:	54dc                	lw	a5,44(s1)
    80004456:	06f04763          	bgtz	a5,800044c4 <end_op+0xbc>
    acquire(&log.lock);
    8000445a:	0001d497          	auipc	s1,0x1d
    8000445e:	2c648493          	addi	s1,s1,710 # 80021720 <log>
    80004462:	8526                	mv	a0,s1
    80004464:	ffffc097          	auipc	ra,0xffffc
    80004468:	772080e7          	jalr	1906(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000446c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004470:	8526                	mv	a0,s1
    80004472:	ffffe097          	auipc	ra,0xffffe
    80004476:	c6e080e7          	jalr	-914(ra) # 800020e0 <wakeup>
    release(&log.lock);
    8000447a:	8526                	mv	a0,s1
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
}
    80004484:	a03d                	j	800044b2 <end_op+0xaa>
    panic("log.committing");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	1ca50513          	addi	a0,a0,458 # 80008650 <syscalls+0x200>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    wakeup(&log);
    80004496:	0001d497          	auipc	s1,0x1d
    8000449a:	28a48493          	addi	s1,s1,650 # 80021720 <log>
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffe097          	auipc	ra,0xffffe
    800044a4:	c40080e7          	jalr	-960(ra) # 800020e0 <wakeup>
  release(&log.lock);
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	7e0080e7          	jalr	2016(ra) # 80000c8a <release>
}
    800044b2:	70e2                	ld	ra,56(sp)
    800044b4:	7442                	ld	s0,48(sp)
    800044b6:	74a2                	ld	s1,40(sp)
    800044b8:	7902                	ld	s2,32(sp)
    800044ba:	69e2                	ld	s3,24(sp)
    800044bc:	6a42                	ld	s4,16(sp)
    800044be:	6aa2                	ld	s5,8(sp)
    800044c0:	6121                	addi	sp,sp,64
    800044c2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044c4:	0001da97          	auipc	s5,0x1d
    800044c8:	28ca8a93          	addi	s5,s5,652 # 80021750 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044cc:	0001da17          	auipc	s4,0x1d
    800044d0:	254a0a13          	addi	s4,s4,596 # 80021720 <log>
    800044d4:	018a2583          	lw	a1,24(s4)
    800044d8:	012585bb          	addw	a1,a1,s2
    800044dc:	2585                	addiw	a1,a1,1
    800044de:	028a2503          	lw	a0,40(s4)
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	cca080e7          	jalr	-822(ra) # 800031ac <bread>
    800044ea:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044ec:	000aa583          	lw	a1,0(s5)
    800044f0:	028a2503          	lw	a0,40(s4)
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	cb8080e7          	jalr	-840(ra) # 800031ac <bread>
    800044fc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044fe:	40000613          	li	a2,1024
    80004502:	05850593          	addi	a1,a0,88
    80004506:	05848513          	addi	a0,s1,88
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	824080e7          	jalr	-2012(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	d8a080e7          	jalr	-630(ra) # 8000329e <bwrite>
    brelse(from);
    8000451c:	854e                	mv	a0,s3
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	dbe080e7          	jalr	-578(ra) # 800032dc <brelse>
    brelse(to);
    80004526:	8526                	mv	a0,s1
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	db4080e7          	jalr	-588(ra) # 800032dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004530:	2905                	addiw	s2,s2,1
    80004532:	0a91                	addi	s5,s5,4
    80004534:	02ca2783          	lw	a5,44(s4)
    80004538:	f8f94ee3          	blt	s2,a5,800044d4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	c6a080e7          	jalr	-918(ra) # 800041a6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004544:	4501                	li	a0,0
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	cda080e7          	jalr	-806(ra) # 80004220 <install_trans>
    log.lh.n = 0;
    8000454e:	0001d797          	auipc	a5,0x1d
    80004552:	1e07af23          	sw	zero,510(a5) # 8002174c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	c50080e7          	jalr	-944(ra) # 800041a6 <write_head>
    8000455e:	bdf5                	j	8000445a <end_op+0x52>

0000000080004560 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004560:	1101                	addi	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	e04a                	sd	s2,0(sp)
    8000456a:	1000                	addi	s0,sp,32
    8000456c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000456e:	0001d917          	auipc	s2,0x1d
    80004572:	1b290913          	addi	s2,s2,434 # 80021720 <log>
    80004576:	854a                	mv	a0,s2
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	65e080e7          	jalr	1630(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004580:	02c92603          	lw	a2,44(s2)
    80004584:	47f5                	li	a5,29
    80004586:	06c7c563          	blt	a5,a2,800045f0 <log_write+0x90>
    8000458a:	0001d797          	auipc	a5,0x1d
    8000458e:	1b27a783          	lw	a5,434(a5) # 8002173c <log+0x1c>
    80004592:	37fd                	addiw	a5,a5,-1
    80004594:	04f65e63          	bge	a2,a5,800045f0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004598:	0001d797          	auipc	a5,0x1d
    8000459c:	1a87a783          	lw	a5,424(a5) # 80021740 <log+0x20>
    800045a0:	06f05063          	blez	a5,80004600 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045a4:	4781                	li	a5,0
    800045a6:	06c05563          	blez	a2,80004610 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045aa:	44cc                	lw	a1,12(s1)
    800045ac:	0001d717          	auipc	a4,0x1d
    800045b0:	1a470713          	addi	a4,a4,420 # 80021750 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045b4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045b6:	4314                	lw	a3,0(a4)
    800045b8:	04b68c63          	beq	a3,a1,80004610 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045bc:	2785                	addiw	a5,a5,1
    800045be:	0711                	addi	a4,a4,4
    800045c0:	fef61be3          	bne	a2,a5,800045b6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045c4:	0621                	addi	a2,a2,8
    800045c6:	060a                	slli	a2,a2,0x2
    800045c8:	0001d797          	auipc	a5,0x1d
    800045cc:	15878793          	addi	a5,a5,344 # 80021720 <log>
    800045d0:	963e                	add	a2,a2,a5
    800045d2:	44dc                	lw	a5,12(s1)
    800045d4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045d6:	8526                	mv	a0,s1
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	da2080e7          	jalr	-606(ra) # 8000337a <bpin>
    log.lh.n++;
    800045e0:	0001d717          	auipc	a4,0x1d
    800045e4:	14070713          	addi	a4,a4,320 # 80021720 <log>
    800045e8:	575c                	lw	a5,44(a4)
    800045ea:	2785                	addiw	a5,a5,1
    800045ec:	d75c                	sw	a5,44(a4)
    800045ee:	a835                	j	8000462a <log_write+0xca>
    panic("too big a transaction");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	07050513          	addi	a0,a0,112 # 80008660 <syscalls+0x210>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004600:	00004517          	auipc	a0,0x4
    80004604:	07850513          	addi	a0,a0,120 # 80008678 <syscalls+0x228>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004610:	00878713          	addi	a4,a5,8
    80004614:	00271693          	slli	a3,a4,0x2
    80004618:	0001d717          	auipc	a4,0x1d
    8000461c:	10870713          	addi	a4,a4,264 # 80021720 <log>
    80004620:	9736                	add	a4,a4,a3
    80004622:	44d4                	lw	a3,12(s1)
    80004624:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004626:	faf608e3          	beq	a2,a5,800045d6 <log_write+0x76>
  }
  release(&log.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	0f650513          	addi	a0,a0,246 # 80021720 <log>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	658080e7          	jalr	1624(ra) # 80000c8a <release>
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004646:	1101                	addi	sp,sp,-32
    80004648:	ec06                	sd	ra,24(sp)
    8000464a:	e822                	sd	s0,16(sp)
    8000464c:	e426                	sd	s1,8(sp)
    8000464e:	e04a                	sd	s2,0(sp)
    80004650:	1000                	addi	s0,sp,32
    80004652:	84aa                	mv	s1,a0
    80004654:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004656:	00004597          	auipc	a1,0x4
    8000465a:	04258593          	addi	a1,a1,66 # 80008698 <syscalls+0x248>
    8000465e:	0521                	addi	a0,a0,8
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	4e6080e7          	jalr	1254(ra) # 80000b46 <initlock>
  lk->name = name;
    80004668:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000466c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004670:	0204a423          	sw	zero,40(s1)
}
    80004674:	60e2                	ld	ra,24(sp)
    80004676:	6442                	ld	s0,16(sp)
    80004678:	64a2                	ld	s1,8(sp)
    8000467a:	6902                	ld	s2,0(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004680:	1101                	addi	sp,sp,-32
    80004682:	ec06                	sd	ra,24(sp)
    80004684:	e822                	sd	s0,16(sp)
    80004686:	e426                	sd	s1,8(sp)
    80004688:	e04a                	sd	s2,0(sp)
    8000468a:	1000                	addi	s0,sp,32
    8000468c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000468e:	00850913          	addi	s2,a0,8
    80004692:	854a                	mv	a0,s2
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	542080e7          	jalr	1346(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000469c:	409c                	lw	a5,0(s1)
    8000469e:	cb89                	beqz	a5,800046b0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046a0:	85ca                	mv	a1,s2
    800046a2:	8526                	mv	a0,s1
    800046a4:	ffffe097          	auipc	ra,0xffffe
    800046a8:	9d8080e7          	jalr	-1576(ra) # 8000207c <sleep>
  while (lk->locked) {
    800046ac:	409c                	lw	a5,0(s1)
    800046ae:	fbed                	bnez	a5,800046a0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046b0:	4785                	li	a5,1
    800046b2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	2f8080e7          	jalr	760(ra) # 800019ac <myproc>
    800046bc:	591c                	lw	a5,48(a0)
    800046be:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046c0:	854a                	mv	a0,s2
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
}
    800046ca:	60e2                	ld	ra,24(sp)
    800046cc:	6442                	ld	s0,16(sp)
    800046ce:	64a2                	ld	s1,8(sp)
    800046d0:	6902                	ld	s2,0(sp)
    800046d2:	6105                	addi	sp,sp,32
    800046d4:	8082                	ret

00000000800046d6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046d6:	1101                	addi	sp,sp,-32
    800046d8:	ec06                	sd	ra,24(sp)
    800046da:	e822                	sd	s0,16(sp)
    800046dc:	e426                	sd	s1,8(sp)
    800046de:	e04a                	sd	s2,0(sp)
    800046e0:	1000                	addi	s0,sp,32
    800046e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046e4:	00850913          	addi	s2,a0,8
    800046e8:	854a                	mv	a0,s2
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	4ec080e7          	jalr	1260(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800046f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046f6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046fa:	8526                	mv	a0,s1
    800046fc:	ffffe097          	auipc	ra,0xffffe
    80004700:	9e4080e7          	jalr	-1564(ra) # 800020e0 <wakeup>
  release(&lk->lk);
    80004704:	854a                	mv	a0,s2
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	584080e7          	jalr	1412(ra) # 80000c8a <release>
}
    8000470e:	60e2                	ld	ra,24(sp)
    80004710:	6442                	ld	s0,16(sp)
    80004712:	64a2                	ld	s1,8(sp)
    80004714:	6902                	ld	s2,0(sp)
    80004716:	6105                	addi	sp,sp,32
    80004718:	8082                	ret

000000008000471a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000471a:	7179                	addi	sp,sp,-48
    8000471c:	f406                	sd	ra,40(sp)
    8000471e:	f022                	sd	s0,32(sp)
    80004720:	ec26                	sd	s1,24(sp)
    80004722:	e84a                	sd	s2,16(sp)
    80004724:	e44e                	sd	s3,8(sp)
    80004726:	1800                	addi	s0,sp,48
    80004728:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000472a:	00850913          	addi	s2,a0,8
    8000472e:	854a                	mv	a0,s2
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4a6080e7          	jalr	1190(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004738:	409c                	lw	a5,0(s1)
    8000473a:	ef99                	bnez	a5,80004758 <holdingsleep+0x3e>
    8000473c:	4481                	li	s1,0
  release(&lk->lk);
    8000473e:	854a                	mv	a0,s2
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	54a080e7          	jalr	1354(ra) # 80000c8a <release>
  return r;
}
    80004748:	8526                	mv	a0,s1
    8000474a:	70a2                	ld	ra,40(sp)
    8000474c:	7402                	ld	s0,32(sp)
    8000474e:	64e2                	ld	s1,24(sp)
    80004750:	6942                	ld	s2,16(sp)
    80004752:	69a2                	ld	s3,8(sp)
    80004754:	6145                	addi	sp,sp,48
    80004756:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004758:	0284a983          	lw	s3,40(s1)
    8000475c:	ffffd097          	auipc	ra,0xffffd
    80004760:	250080e7          	jalr	592(ra) # 800019ac <myproc>
    80004764:	5904                	lw	s1,48(a0)
    80004766:	413484b3          	sub	s1,s1,s3
    8000476a:	0014b493          	seqz	s1,s1
    8000476e:	bfc1                	j	8000473e <holdingsleep+0x24>

0000000080004770 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004770:	1141                	addi	sp,sp,-16
    80004772:	e406                	sd	ra,8(sp)
    80004774:	e022                	sd	s0,0(sp)
    80004776:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004778:	00004597          	auipc	a1,0x4
    8000477c:	f3058593          	addi	a1,a1,-208 # 800086a8 <syscalls+0x258>
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	0e850513          	addi	a0,a0,232 # 80021868 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	3be080e7          	jalr	958(ra) # 80000b46 <initlock>
}
    80004790:	60a2                	ld	ra,8(sp)
    80004792:	6402                	ld	s0,0(sp)
    80004794:	0141                	addi	sp,sp,16
    80004796:	8082                	ret

0000000080004798 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004798:	1101                	addi	sp,sp,-32
    8000479a:	ec06                	sd	ra,24(sp)
    8000479c:	e822                	sd	s0,16(sp)
    8000479e:	e426                	sd	s1,8(sp)
    800047a0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047a2:	0001d517          	auipc	a0,0x1d
    800047a6:	0c650513          	addi	a0,a0,198 # 80021868 <ftable>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	42c080e7          	jalr	1068(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047b2:	0001d497          	auipc	s1,0x1d
    800047b6:	0ce48493          	addi	s1,s1,206 # 80021880 <ftable+0x18>
    800047ba:	0001e717          	auipc	a4,0x1e
    800047be:	06670713          	addi	a4,a4,102 # 80022820 <disk>
    if(f->ref == 0){
    800047c2:	40dc                	lw	a5,4(s1)
    800047c4:	cf99                	beqz	a5,800047e2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c6:	02848493          	addi	s1,s1,40
    800047ca:	fee49ce3          	bne	s1,a4,800047c2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047ce:	0001d517          	auipc	a0,0x1d
    800047d2:	09a50513          	addi	a0,a0,154 # 80021868 <ftable>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4b4080e7          	jalr	1204(ra) # 80000c8a <release>
  return 0;
    800047de:	4481                	li	s1,0
    800047e0:	a819                	j	800047f6 <filealloc+0x5e>
      f->ref = 1;
    800047e2:	4785                	li	a5,1
    800047e4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047e6:	0001d517          	auipc	a0,0x1d
    800047ea:	08250513          	addi	a0,a0,130 # 80021868 <ftable>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	49c080e7          	jalr	1180(ra) # 80000c8a <release>
}
    800047f6:	8526                	mv	a0,s1
    800047f8:	60e2                	ld	ra,24(sp)
    800047fa:	6442                	ld	s0,16(sp)
    800047fc:	64a2                	ld	s1,8(sp)
    800047fe:	6105                	addi	sp,sp,32
    80004800:	8082                	ret

0000000080004802 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004802:	1101                	addi	sp,sp,-32
    80004804:	ec06                	sd	ra,24(sp)
    80004806:	e822                	sd	s0,16(sp)
    80004808:	e426                	sd	s1,8(sp)
    8000480a:	1000                	addi	s0,sp,32
    8000480c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000480e:	0001d517          	auipc	a0,0x1d
    80004812:	05a50513          	addi	a0,a0,90 # 80021868 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	3c0080e7          	jalr	960(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000481e:	40dc                	lw	a5,4(s1)
    80004820:	02f05263          	blez	a5,80004844 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004824:	2785                	addiw	a5,a5,1
    80004826:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	04050513          	addi	a0,a0,64 # 80021868 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	45a080e7          	jalr	1114(ra) # 80000c8a <release>
  return f;
}
    80004838:	8526                	mv	a0,s1
    8000483a:	60e2                	ld	ra,24(sp)
    8000483c:	6442                	ld	s0,16(sp)
    8000483e:	64a2                	ld	s1,8(sp)
    80004840:	6105                	addi	sp,sp,32
    80004842:	8082                	ret
    panic("filedup");
    80004844:	00004517          	auipc	a0,0x4
    80004848:	e6c50513          	addi	a0,a0,-404 # 800086b0 <syscalls+0x260>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>

0000000080004854 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004854:	7139                	addi	sp,sp,-64
    80004856:	fc06                	sd	ra,56(sp)
    80004858:	f822                	sd	s0,48(sp)
    8000485a:	f426                	sd	s1,40(sp)
    8000485c:	f04a                	sd	s2,32(sp)
    8000485e:	ec4e                	sd	s3,24(sp)
    80004860:	e852                	sd	s4,16(sp)
    80004862:	e456                	sd	s5,8(sp)
    80004864:	0080                	addi	s0,sp,64
    80004866:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004868:	0001d517          	auipc	a0,0x1d
    8000486c:	00050513          	mv	a0,a0
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	366080e7          	jalr	870(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004878:	40dc                	lw	a5,4(s1)
    8000487a:	06f05163          	blez	a5,800048dc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000487e:	37fd                	addiw	a5,a5,-1
    80004880:	0007871b          	sext.w	a4,a5
    80004884:	c0dc                	sw	a5,4(s1)
    80004886:	06e04363          	bgtz	a4,800048ec <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000488a:	0004a903          	lw	s2,0(s1)
    8000488e:	0094ca83          	lbu	s5,9(s1)
    80004892:	0104ba03          	ld	s4,16(s1)
    80004896:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000489a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000489e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048a2:	0001d517          	auipc	a0,0x1d
    800048a6:	fc650513          	addi	a0,a0,-58 # 80021868 <ftable>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	3e0080e7          	jalr	992(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048b2:	4785                	li	a5,1
    800048b4:	04f90d63          	beq	s2,a5,8000490e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048b8:	3979                	addiw	s2,s2,-2
    800048ba:	4785                	li	a5,1
    800048bc:	0527e063          	bltu	a5,s2,800048fc <fileclose+0xa8>
    begin_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	ac8080e7          	jalr	-1336(ra) # 80004388 <begin_op>
    iput(ff.ip);
    800048c8:	854e                	mv	a0,s3
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	2b6080e7          	jalr	694(ra) # 80003b80 <iput>
    end_op();
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	b36080e7          	jalr	-1226(ra) # 80004408 <end_op>
    800048da:	a00d                	j	800048fc <fileclose+0xa8>
    panic("fileclose");
    800048dc:	00004517          	auipc	a0,0x4
    800048e0:	ddc50513          	addi	a0,a0,-548 # 800086b8 <syscalls+0x268>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	c5a080e7          	jalr	-934(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048ec:	0001d517          	auipc	a0,0x1d
    800048f0:	f7c50513          	addi	a0,a0,-132 # 80021868 <ftable>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	396080e7          	jalr	918(ra) # 80000c8a <release>
  }
}
    800048fc:	70e2                	ld	ra,56(sp)
    800048fe:	7442                	ld	s0,48(sp)
    80004900:	74a2                	ld	s1,40(sp)
    80004902:	7902                	ld	s2,32(sp)
    80004904:	69e2                	ld	s3,24(sp)
    80004906:	6a42                	ld	s4,16(sp)
    80004908:	6aa2                	ld	s5,8(sp)
    8000490a:	6121                	addi	sp,sp,64
    8000490c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000490e:	85d6                	mv	a1,s5
    80004910:	8552                	mv	a0,s4
    80004912:	00000097          	auipc	ra,0x0
    80004916:	34c080e7          	jalr	844(ra) # 80004c5e <pipeclose>
    8000491a:	b7cd                	j	800048fc <fileclose+0xa8>

000000008000491c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000491c:	715d                	addi	sp,sp,-80
    8000491e:	e486                	sd	ra,72(sp)
    80004920:	e0a2                	sd	s0,64(sp)
    80004922:	fc26                	sd	s1,56(sp)
    80004924:	f84a                	sd	s2,48(sp)
    80004926:	f44e                	sd	s3,40(sp)
    80004928:	0880                	addi	s0,sp,80
    8000492a:	84aa                	mv	s1,a0
    8000492c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000492e:	ffffd097          	auipc	ra,0xffffd
    80004932:	07e080e7          	jalr	126(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004936:	409c                	lw	a5,0(s1)
    80004938:	37f9                	addiw	a5,a5,-2
    8000493a:	4705                	li	a4,1
    8000493c:	04f76763          	bltu	a4,a5,8000498a <filestat+0x6e>
    80004940:	892a                	mv	s2,a0
    ilock(f->ip);
    80004942:	6c88                	ld	a0,24(s1)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	082080e7          	jalr	130(ra) # 800039c6 <ilock>
    stati(f->ip, &st);
    8000494c:	fb840593          	addi	a1,s0,-72
    80004950:	6c88                	ld	a0,24(s1)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	2fe080e7          	jalr	766(ra) # 80003c50 <stati>
    iunlock(f->ip);
    8000495a:	6c88                	ld	a0,24(s1)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	12c080e7          	jalr	300(ra) # 80003a88 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004964:	46e1                	li	a3,24
    80004966:	fb840613          	addi	a2,s0,-72
    8000496a:	85ce                	mv	a1,s3
    8000496c:	05893503          	ld	a0,88(s2)
    80004970:	ffffd097          	auipc	ra,0xffffd
    80004974:	cf8080e7          	jalr	-776(ra) # 80001668 <copyout>
    80004978:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000497c:	60a6                	ld	ra,72(sp)
    8000497e:	6406                	ld	s0,64(sp)
    80004980:	74e2                	ld	s1,56(sp)
    80004982:	7942                	ld	s2,48(sp)
    80004984:	79a2                	ld	s3,40(sp)
    80004986:	6161                	addi	sp,sp,80
    80004988:	8082                	ret
  return -1;
    8000498a:	557d                	li	a0,-1
    8000498c:	bfc5                	j	8000497c <filestat+0x60>

000000008000498e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000498e:	7179                	addi	sp,sp,-48
    80004990:	f406                	sd	ra,40(sp)
    80004992:	f022                	sd	s0,32(sp)
    80004994:	ec26                	sd	s1,24(sp)
    80004996:	e84a                	sd	s2,16(sp)
    80004998:	e44e                	sd	s3,8(sp)
    8000499a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000499c:	00854783          	lbu	a5,8(a0)
    800049a0:	c3d5                	beqz	a5,80004a44 <fileread+0xb6>
    800049a2:	84aa                	mv	s1,a0
    800049a4:	89ae                	mv	s3,a1
    800049a6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049a8:	411c                	lw	a5,0(a0)
    800049aa:	4705                	li	a4,1
    800049ac:	04e78963          	beq	a5,a4,800049fe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b0:	470d                	li	a4,3
    800049b2:	04e78d63          	beq	a5,a4,80004a0c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049b6:	4709                	li	a4,2
    800049b8:	06e79e63          	bne	a5,a4,80004a34 <fileread+0xa6>
    ilock(f->ip);
    800049bc:	6d08                	ld	a0,24(a0)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	008080e7          	jalr	8(ra) # 800039c6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049c6:	874a                	mv	a4,s2
    800049c8:	5094                	lw	a3,32(s1)
    800049ca:	864e                	mv	a2,s3
    800049cc:	4585                	li	a1,1
    800049ce:	6c88                	ld	a0,24(s1)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	2aa080e7          	jalr	682(ra) # 80003c7a <readi>
    800049d8:	892a                	mv	s2,a0
    800049da:	00a05563          	blez	a0,800049e4 <fileread+0x56>
      f->off += r;
    800049de:	509c                	lw	a5,32(s1)
    800049e0:	9fa9                	addw	a5,a5,a0
    800049e2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049e4:	6c88                	ld	a0,24(s1)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	0a2080e7          	jalr	162(ra) # 80003a88 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049ee:	854a                	mv	a0,s2
    800049f0:	70a2                	ld	ra,40(sp)
    800049f2:	7402                	ld	s0,32(sp)
    800049f4:	64e2                	ld	s1,24(sp)
    800049f6:	6942                	ld	s2,16(sp)
    800049f8:	69a2                	ld	s3,8(sp)
    800049fa:	6145                	addi	sp,sp,48
    800049fc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049fe:	6908                	ld	a0,16(a0)
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	3c6080e7          	jalr	966(ra) # 80004dc6 <piperead>
    80004a08:	892a                	mv	s2,a0
    80004a0a:	b7d5                	j	800049ee <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a0c:	02451783          	lh	a5,36(a0)
    80004a10:	03079693          	slli	a3,a5,0x30
    80004a14:	92c1                	srli	a3,a3,0x30
    80004a16:	4725                	li	a4,9
    80004a18:	02d76863          	bltu	a4,a3,80004a48 <fileread+0xba>
    80004a1c:	0792                	slli	a5,a5,0x4
    80004a1e:	0001d717          	auipc	a4,0x1d
    80004a22:	daa70713          	addi	a4,a4,-598 # 800217c8 <devsw>
    80004a26:	97ba                	add	a5,a5,a4
    80004a28:	639c                	ld	a5,0(a5)
    80004a2a:	c38d                	beqz	a5,80004a4c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a2c:	4505                	li	a0,1
    80004a2e:	9782                	jalr	a5
    80004a30:	892a                	mv	s2,a0
    80004a32:	bf75                	j	800049ee <fileread+0x60>
    panic("fileread");
    80004a34:	00004517          	auipc	a0,0x4
    80004a38:	c9450513          	addi	a0,a0,-876 # 800086c8 <syscalls+0x278>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
    return -1;
    80004a44:	597d                	li	s2,-1
    80004a46:	b765                	j	800049ee <fileread+0x60>
      return -1;
    80004a48:	597d                	li	s2,-1
    80004a4a:	b755                	j	800049ee <fileread+0x60>
    80004a4c:	597d                	li	s2,-1
    80004a4e:	b745                	j	800049ee <fileread+0x60>

0000000080004a50 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a50:	715d                	addi	sp,sp,-80
    80004a52:	e486                	sd	ra,72(sp)
    80004a54:	e0a2                	sd	s0,64(sp)
    80004a56:	fc26                	sd	s1,56(sp)
    80004a58:	f84a                	sd	s2,48(sp)
    80004a5a:	f44e                	sd	s3,40(sp)
    80004a5c:	f052                	sd	s4,32(sp)
    80004a5e:	ec56                	sd	s5,24(sp)
    80004a60:	e85a                	sd	s6,16(sp)
    80004a62:	e45e                	sd	s7,8(sp)
    80004a64:	e062                	sd	s8,0(sp)
    80004a66:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a68:	00954783          	lbu	a5,9(a0)
    80004a6c:	10078663          	beqz	a5,80004b78 <filewrite+0x128>
    80004a70:	892a                	mv	s2,a0
    80004a72:	8aae                	mv	s5,a1
    80004a74:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a76:	411c                	lw	a5,0(a0)
    80004a78:	4705                	li	a4,1
    80004a7a:	02e78263          	beq	a5,a4,80004a9e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a7e:	470d                	li	a4,3
    80004a80:	02e78663          	beq	a5,a4,80004aac <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a84:	4709                	li	a4,2
    80004a86:	0ee79163          	bne	a5,a4,80004b68 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a8a:	0ac05d63          	blez	a2,80004b44 <filewrite+0xf4>
    int i = 0;
    80004a8e:	4981                	li	s3,0
    80004a90:	6b05                	lui	s6,0x1
    80004a92:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a96:	6b85                	lui	s7,0x1
    80004a98:	c00b8b9b          	addiw	s7,s7,-1024
    80004a9c:	a861                	j	80004b34 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a9e:	6908                	ld	a0,16(a0)
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	22e080e7          	jalr	558(ra) # 80004cce <pipewrite>
    80004aa8:	8a2a                	mv	s4,a0
    80004aaa:	a045                	j	80004b4a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aac:	02451783          	lh	a5,36(a0)
    80004ab0:	03079693          	slli	a3,a5,0x30
    80004ab4:	92c1                	srli	a3,a3,0x30
    80004ab6:	4725                	li	a4,9
    80004ab8:	0cd76263          	bltu	a4,a3,80004b7c <filewrite+0x12c>
    80004abc:	0792                	slli	a5,a5,0x4
    80004abe:	0001d717          	auipc	a4,0x1d
    80004ac2:	d0a70713          	addi	a4,a4,-758 # 800217c8 <devsw>
    80004ac6:	97ba                	add	a5,a5,a4
    80004ac8:	679c                	ld	a5,8(a5)
    80004aca:	cbdd                	beqz	a5,80004b80 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004acc:	4505                	li	a0,1
    80004ace:	9782                	jalr	a5
    80004ad0:	8a2a                	mv	s4,a0
    80004ad2:	a8a5                	j	80004b4a <filewrite+0xfa>
    80004ad4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	8b0080e7          	jalr	-1872(ra) # 80004388 <begin_op>
      ilock(f->ip);
    80004ae0:	01893503          	ld	a0,24(s2)
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	ee2080e7          	jalr	-286(ra) # 800039c6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aec:	8762                	mv	a4,s8
    80004aee:	02092683          	lw	a3,32(s2)
    80004af2:	01598633          	add	a2,s3,s5
    80004af6:	4585                	li	a1,1
    80004af8:	01893503          	ld	a0,24(s2)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	276080e7          	jalr	630(ra) # 80003d72 <writei>
    80004b04:	84aa                	mv	s1,a0
    80004b06:	00a05763          	blez	a0,80004b14 <filewrite+0xc4>
        f->off += r;
    80004b0a:	02092783          	lw	a5,32(s2)
    80004b0e:	9fa9                	addw	a5,a5,a0
    80004b10:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b14:	01893503          	ld	a0,24(s2)
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	f70080e7          	jalr	-144(ra) # 80003a88 <iunlock>
      end_op();
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	8e8080e7          	jalr	-1816(ra) # 80004408 <end_op>

      if(r != n1){
    80004b28:	009c1f63          	bne	s8,s1,80004b46 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b2c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b30:	0149db63          	bge	s3,s4,80004b46 <filewrite+0xf6>
      int n1 = n - i;
    80004b34:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b38:	84be                	mv	s1,a5
    80004b3a:	2781                	sext.w	a5,a5
    80004b3c:	f8fb5ce3          	bge	s6,a5,80004ad4 <filewrite+0x84>
    80004b40:	84de                	mv	s1,s7
    80004b42:	bf49                	j	80004ad4 <filewrite+0x84>
    int i = 0;
    80004b44:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b46:	013a1f63          	bne	s4,s3,80004b64 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b4a:	8552                	mv	a0,s4
    80004b4c:	60a6                	ld	ra,72(sp)
    80004b4e:	6406                	ld	s0,64(sp)
    80004b50:	74e2                	ld	s1,56(sp)
    80004b52:	7942                	ld	s2,48(sp)
    80004b54:	79a2                	ld	s3,40(sp)
    80004b56:	7a02                	ld	s4,32(sp)
    80004b58:	6ae2                	ld	s5,24(sp)
    80004b5a:	6b42                	ld	s6,16(sp)
    80004b5c:	6ba2                	ld	s7,8(sp)
    80004b5e:	6c02                	ld	s8,0(sp)
    80004b60:	6161                	addi	sp,sp,80
    80004b62:	8082                	ret
    ret = (i == n ? n : -1);
    80004b64:	5a7d                	li	s4,-1
    80004b66:	b7d5                	j	80004b4a <filewrite+0xfa>
    panic("filewrite");
    80004b68:	00004517          	auipc	a0,0x4
    80004b6c:	b7050513          	addi	a0,a0,-1168 # 800086d8 <syscalls+0x288>
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	9ce080e7          	jalr	-1586(ra) # 8000053e <panic>
    return -1;
    80004b78:	5a7d                	li	s4,-1
    80004b7a:	bfc1                	j	80004b4a <filewrite+0xfa>
      return -1;
    80004b7c:	5a7d                	li	s4,-1
    80004b7e:	b7f1                	j	80004b4a <filewrite+0xfa>
    80004b80:	5a7d                	li	s4,-1
    80004b82:	b7e1                	j	80004b4a <filewrite+0xfa>

0000000080004b84 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b84:	7179                	addi	sp,sp,-48
    80004b86:	f406                	sd	ra,40(sp)
    80004b88:	f022                	sd	s0,32(sp)
    80004b8a:	ec26                	sd	s1,24(sp)
    80004b8c:	e84a                	sd	s2,16(sp)
    80004b8e:	e44e                	sd	s3,8(sp)
    80004b90:	e052                	sd	s4,0(sp)
    80004b92:	1800                	addi	s0,sp,48
    80004b94:	84aa                	mv	s1,a0
    80004b96:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b98:	0005b023          	sd	zero,0(a1)
    80004b9c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	bf8080e7          	jalr	-1032(ra) # 80004798 <filealloc>
    80004ba8:	e088                	sd	a0,0(s1)
    80004baa:	c551                	beqz	a0,80004c36 <pipealloc+0xb2>
    80004bac:	00000097          	auipc	ra,0x0
    80004bb0:	bec080e7          	jalr	-1044(ra) # 80004798 <filealloc>
    80004bb4:	00aa3023          	sd	a0,0(s4)
    80004bb8:	c92d                	beqz	a0,80004c2a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	f2c080e7          	jalr	-212(ra) # 80000ae6 <kalloc>
    80004bc2:	892a                	mv	s2,a0
    80004bc4:	c125                	beqz	a0,80004c24 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bc6:	4985                	li	s3,1
    80004bc8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bcc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bd0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bd4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bd8:	00004597          	auipc	a1,0x4
    80004bdc:	b1058593          	addi	a1,a1,-1264 # 800086e8 <syscalls+0x298>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	f66080e7          	jalr	-154(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004be8:	609c                	ld	a5,0(s1)
    80004bea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bee:	609c                	ld	a5,0(s1)
    80004bf0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bf4:	609c                	ld	a5,0(s1)
    80004bf6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bfa:	609c                	ld	a5,0(s1)
    80004bfc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c00:	000a3783          	ld	a5,0(s4)
    80004c04:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c08:	000a3783          	ld	a5,0(s4)
    80004c0c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c10:	000a3783          	ld	a5,0(s4)
    80004c14:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c18:	000a3783          	ld	a5,0(s4)
    80004c1c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c20:	4501                	li	a0,0
    80004c22:	a025                	j	80004c4a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c24:	6088                	ld	a0,0(s1)
    80004c26:	e501                	bnez	a0,80004c2e <pipealloc+0xaa>
    80004c28:	a039                	j	80004c36 <pipealloc+0xb2>
    80004c2a:	6088                	ld	a0,0(s1)
    80004c2c:	c51d                	beqz	a0,80004c5a <pipealloc+0xd6>
    fileclose(*f0);
    80004c2e:	00000097          	auipc	ra,0x0
    80004c32:	c26080e7          	jalr	-986(ra) # 80004854 <fileclose>
  if(*f1)
    80004c36:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c3a:	557d                	li	a0,-1
  if(*f1)
    80004c3c:	c799                	beqz	a5,80004c4a <pipealloc+0xc6>
    fileclose(*f1);
    80004c3e:	853e                	mv	a0,a5
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	c14080e7          	jalr	-1004(ra) # 80004854 <fileclose>
  return -1;
    80004c48:	557d                	li	a0,-1
}
    80004c4a:	70a2                	ld	ra,40(sp)
    80004c4c:	7402                	ld	s0,32(sp)
    80004c4e:	64e2                	ld	s1,24(sp)
    80004c50:	6942                	ld	s2,16(sp)
    80004c52:	69a2                	ld	s3,8(sp)
    80004c54:	6a02                	ld	s4,0(sp)
    80004c56:	6145                	addi	sp,sp,48
    80004c58:	8082                	ret
  return -1;
    80004c5a:	557d                	li	a0,-1
    80004c5c:	b7fd                	j	80004c4a <pipealloc+0xc6>

0000000080004c5e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c5e:	1101                	addi	sp,sp,-32
    80004c60:	ec06                	sd	ra,24(sp)
    80004c62:	e822                	sd	s0,16(sp)
    80004c64:	e426                	sd	s1,8(sp)
    80004c66:	e04a                	sd	s2,0(sp)
    80004c68:	1000                	addi	s0,sp,32
    80004c6a:	84aa                	mv	s1,a0
    80004c6c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	f68080e7          	jalr	-152(ra) # 80000bd6 <acquire>
  if(writable){
    80004c76:	02090d63          	beqz	s2,80004cb0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c7a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c7e:	21848513          	addi	a0,s1,536
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	45e080e7          	jalr	1118(ra) # 800020e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c8a:	2204b783          	ld	a5,544(s1)
    80004c8e:	eb95                	bnez	a5,80004cc2 <pipeclose+0x64>
    release(&pi->lock);
    80004c90:	8526                	mv	a0,s1
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	ff8080e7          	jalr	-8(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	d4e080e7          	jalr	-690(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ca4:	60e2                	ld	ra,24(sp)
    80004ca6:	6442                	ld	s0,16(sp)
    80004ca8:	64a2                	ld	s1,8(sp)
    80004caa:	6902                	ld	s2,0(sp)
    80004cac:	6105                	addi	sp,sp,32
    80004cae:	8082                	ret
    pi->readopen = 0;
    80004cb0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cb4:	21c48513          	addi	a0,s1,540
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	428080e7          	jalr	1064(ra) # 800020e0 <wakeup>
    80004cc0:	b7e9                	j	80004c8a <pipeclose+0x2c>
    release(&pi->lock);
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	fc6080e7          	jalr	-58(ra) # 80000c8a <release>
}
    80004ccc:	bfe1                	j	80004ca4 <pipeclose+0x46>

0000000080004cce <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cce:	711d                	addi	sp,sp,-96
    80004cd0:	ec86                	sd	ra,88(sp)
    80004cd2:	e8a2                	sd	s0,80(sp)
    80004cd4:	e4a6                	sd	s1,72(sp)
    80004cd6:	e0ca                	sd	s2,64(sp)
    80004cd8:	fc4e                	sd	s3,56(sp)
    80004cda:	f852                	sd	s4,48(sp)
    80004cdc:	f456                	sd	s5,40(sp)
    80004cde:	f05a                	sd	s6,32(sp)
    80004ce0:	ec5e                	sd	s7,24(sp)
    80004ce2:	e862                	sd	s8,16(sp)
    80004ce4:	1080                	addi	s0,sp,96
    80004ce6:	84aa                	mv	s1,a0
    80004ce8:	8aae                	mv	s5,a1
    80004cea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	cc0080e7          	jalr	-832(ra) # 800019ac <myproc>
    80004cf4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	ede080e7          	jalr	-290(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d00:	0b405663          	blez	s4,80004dac <pipewrite+0xde>
  int i = 0;
    80004d04:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d06:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d08:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d0c:	21c48b93          	addi	s7,s1,540
    80004d10:	a089                	j	80004d52 <pipewrite+0x84>
      release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
      return -1;
    80004d1c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d1e:	854a                	mv	a0,s2
    80004d20:	60e6                	ld	ra,88(sp)
    80004d22:	6446                	ld	s0,80(sp)
    80004d24:	64a6                	ld	s1,72(sp)
    80004d26:	6906                	ld	s2,64(sp)
    80004d28:	79e2                	ld	s3,56(sp)
    80004d2a:	7a42                	ld	s4,48(sp)
    80004d2c:	7aa2                	ld	s5,40(sp)
    80004d2e:	7b02                	ld	s6,32(sp)
    80004d30:	6be2                	ld	s7,24(sp)
    80004d32:	6c42                	ld	s8,16(sp)
    80004d34:	6125                	addi	sp,sp,96
    80004d36:	8082                	ret
      wakeup(&pi->nread);
    80004d38:	8562                	mv	a0,s8
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	3a6080e7          	jalr	934(ra) # 800020e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d42:	85a6                	mv	a1,s1
    80004d44:	855e                	mv	a0,s7
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	336080e7          	jalr	822(ra) # 8000207c <sleep>
  while(i < n){
    80004d4e:	07495063          	bge	s2,s4,80004dae <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d52:	2204a783          	lw	a5,544(s1)
    80004d56:	dfd5                	beqz	a5,80004d12 <pipewrite+0x44>
    80004d58:	854e                	mv	a0,s3
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	5d6080e7          	jalr	1494(ra) # 80002330 <killed>
    80004d62:	f945                	bnez	a0,80004d12 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d64:	2184a783          	lw	a5,536(s1)
    80004d68:	21c4a703          	lw	a4,540(s1)
    80004d6c:	2007879b          	addiw	a5,a5,512
    80004d70:	fcf704e3          	beq	a4,a5,80004d38 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d74:	4685                	li	a3,1
    80004d76:	01590633          	add	a2,s2,s5
    80004d7a:	faf40593          	addi	a1,s0,-81
    80004d7e:	0589b503          	ld	a0,88(s3)
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	972080e7          	jalr	-1678(ra) # 800016f4 <copyin>
    80004d8a:	03650263          	beq	a0,s6,80004dae <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d8e:	21c4a783          	lw	a5,540(s1)
    80004d92:	0017871b          	addiw	a4,a5,1
    80004d96:	20e4ae23          	sw	a4,540(s1)
    80004d9a:	1ff7f793          	andi	a5,a5,511
    80004d9e:	97a6                	add	a5,a5,s1
    80004da0:	faf44703          	lbu	a4,-81(s0)
    80004da4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004da8:	2905                	addiw	s2,s2,1
    80004daa:	b755                	j	80004d4e <pipewrite+0x80>
  int i = 0;
    80004dac:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dae:	21848513          	addi	a0,s1,536
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	32e080e7          	jalr	814(ra) # 800020e0 <wakeup>
  release(&pi->lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	ece080e7          	jalr	-306(ra) # 80000c8a <release>
  return i;
    80004dc4:	bfa9                	j	80004d1e <pipewrite+0x50>

0000000080004dc6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dc6:	715d                	addi	sp,sp,-80
    80004dc8:	e486                	sd	ra,72(sp)
    80004dca:	e0a2                	sd	s0,64(sp)
    80004dcc:	fc26                	sd	s1,56(sp)
    80004dce:	f84a                	sd	s2,48(sp)
    80004dd0:	f44e                	sd	s3,40(sp)
    80004dd2:	f052                	sd	s4,32(sp)
    80004dd4:	ec56                	sd	s5,24(sp)
    80004dd6:	e85a                	sd	s6,16(sp)
    80004dd8:	0880                	addi	s0,sp,80
    80004dda:	84aa                	mv	s1,a0
    80004ddc:	892e                	mv	s2,a1
    80004dde:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	bcc080e7          	jalr	-1076(ra) # 800019ac <myproc>
    80004de8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dea:	8526                	mv	a0,s1
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	dea080e7          	jalr	-534(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df4:	2184a703          	lw	a4,536(s1)
    80004df8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dfc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e00:	02f71763          	bne	a4,a5,80004e2e <piperead+0x68>
    80004e04:	2244a783          	lw	a5,548(s1)
    80004e08:	c39d                	beqz	a5,80004e2e <piperead+0x68>
    if(killed(pr)){
    80004e0a:	8552                	mv	a0,s4
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	524080e7          	jalr	1316(ra) # 80002330 <killed>
    80004e14:	e941                	bnez	a0,80004ea4 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e16:	85a6                	mv	a1,s1
    80004e18:	854e                	mv	a0,s3
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	262080e7          	jalr	610(ra) # 8000207c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e22:	2184a703          	lw	a4,536(s1)
    80004e26:	21c4a783          	lw	a5,540(s1)
    80004e2a:	fcf70de3          	beq	a4,a5,80004e04 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e2e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e30:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e32:	05505363          	blez	s5,80004e78 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004e36:	2184a783          	lw	a5,536(s1)
    80004e3a:	21c4a703          	lw	a4,540(s1)
    80004e3e:	02f70d63          	beq	a4,a5,80004e78 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e42:	0017871b          	addiw	a4,a5,1
    80004e46:	20e4ac23          	sw	a4,536(s1)
    80004e4a:	1ff7f793          	andi	a5,a5,511
    80004e4e:	97a6                	add	a5,a5,s1
    80004e50:	0187c783          	lbu	a5,24(a5)
    80004e54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e58:	4685                	li	a3,1
    80004e5a:	fbf40613          	addi	a2,s0,-65
    80004e5e:	85ca                	mv	a1,s2
    80004e60:	058a3503          	ld	a0,88(s4)
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	804080e7          	jalr	-2044(ra) # 80001668 <copyout>
    80004e6c:	01650663          	beq	a0,s6,80004e78 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e70:	2985                	addiw	s3,s3,1
    80004e72:	0905                	addi	s2,s2,1
    80004e74:	fd3a91e3          	bne	s5,s3,80004e36 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e78:	21c48513          	addi	a0,s1,540
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	264080e7          	jalr	612(ra) # 800020e0 <wakeup>
  release(&pi->lock);
    80004e84:	8526                	mv	a0,s1
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
  return i;
}
    80004e8e:	854e                	mv	a0,s3
    80004e90:	60a6                	ld	ra,72(sp)
    80004e92:	6406                	ld	s0,64(sp)
    80004e94:	74e2                	ld	s1,56(sp)
    80004e96:	7942                	ld	s2,48(sp)
    80004e98:	79a2                	ld	s3,40(sp)
    80004e9a:	7a02                	ld	s4,32(sp)
    80004e9c:	6ae2                	ld	s5,24(sp)
    80004e9e:	6b42                	ld	s6,16(sp)
    80004ea0:	6161                	addi	sp,sp,80
    80004ea2:	8082                	ret
      release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
      return -1;
    80004eae:	59fd                	li	s3,-1
    80004eb0:	bff9                	j	80004e8e <piperead+0xc8>

0000000080004eb2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004eb2:	1141                	addi	sp,sp,-16
    80004eb4:	e422                	sd	s0,8(sp)
    80004eb6:	0800                	addi	s0,sp,16
    80004eb8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004eba:	8905                	andi	a0,a0,1
    80004ebc:	c111                	beqz	a0,80004ec0 <flags2perm+0xe>
      perm = PTE_X;
    80004ebe:	4521                	li	a0,8
    if(flags & 0x2)
    80004ec0:	8b89                	andi	a5,a5,2
    80004ec2:	c399                	beqz	a5,80004ec8 <flags2perm+0x16>
      perm |= PTE_W;
    80004ec4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ec8:	6422                	ld	s0,8(sp)
    80004eca:	0141                	addi	sp,sp,16
    80004ecc:	8082                	ret

0000000080004ece <exec>:

int
exec(char *path, char **argv)
{
    80004ece:	de010113          	addi	sp,sp,-544
    80004ed2:	20113c23          	sd	ra,536(sp)
    80004ed6:	20813823          	sd	s0,528(sp)
    80004eda:	20913423          	sd	s1,520(sp)
    80004ede:	21213023          	sd	s2,512(sp)
    80004ee2:	ffce                	sd	s3,504(sp)
    80004ee4:	fbd2                	sd	s4,496(sp)
    80004ee6:	f7d6                	sd	s5,488(sp)
    80004ee8:	f3da                	sd	s6,480(sp)
    80004eea:	efde                	sd	s7,472(sp)
    80004eec:	ebe2                	sd	s8,464(sp)
    80004eee:	e7e6                	sd	s9,456(sp)
    80004ef0:	e3ea                	sd	s10,448(sp)
    80004ef2:	ff6e                	sd	s11,440(sp)
    80004ef4:	1400                	addi	s0,sp,544
    80004ef6:	892a                	mv	s2,a0
    80004ef8:	dea43423          	sd	a0,-536(s0)
    80004efc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	aac080e7          	jalr	-1364(ra) # 800019ac <myproc>
    80004f08:	84aa                	mv	s1,a0

  begin_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	47e080e7          	jalr	1150(ra) # 80004388 <begin_op>

  if((ip = namei(path)) == 0){
    80004f12:	854a                	mv	a0,s2
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	258080e7          	jalr	600(ra) # 8000416c <namei>
    80004f1c:	c93d                	beqz	a0,80004f92 <exec+0xc4>
    80004f1e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	aa6080e7          	jalr	-1370(ra) # 800039c6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f28:	04000713          	li	a4,64
    80004f2c:	4681                	li	a3,0
    80004f2e:	e5040613          	addi	a2,s0,-432
    80004f32:	4581                	li	a1,0
    80004f34:	8556                	mv	a0,s5
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	d44080e7          	jalr	-700(ra) # 80003c7a <readi>
    80004f3e:	04000793          	li	a5,64
    80004f42:	00f51a63          	bne	a0,a5,80004f56 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f46:	e5042703          	lw	a4,-432(s0)
    80004f4a:	464c47b7          	lui	a5,0x464c4
    80004f4e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f52:	04f70663          	beq	a4,a5,80004f9e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f56:	8556                	mv	a0,s5
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	cd0080e7          	jalr	-816(ra) # 80003c28 <iunlockput>
    end_op();
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	4a8080e7          	jalr	1192(ra) # 80004408 <end_op>
  }
  return -1;
    80004f68:	557d                	li	a0,-1
}
    80004f6a:	21813083          	ld	ra,536(sp)
    80004f6e:	21013403          	ld	s0,528(sp)
    80004f72:	20813483          	ld	s1,520(sp)
    80004f76:	20013903          	ld	s2,512(sp)
    80004f7a:	79fe                	ld	s3,504(sp)
    80004f7c:	7a5e                	ld	s4,496(sp)
    80004f7e:	7abe                	ld	s5,488(sp)
    80004f80:	7b1e                	ld	s6,480(sp)
    80004f82:	6bfe                	ld	s7,472(sp)
    80004f84:	6c5e                	ld	s8,464(sp)
    80004f86:	6cbe                	ld	s9,456(sp)
    80004f88:	6d1e                	ld	s10,448(sp)
    80004f8a:	7dfa                	ld	s11,440(sp)
    80004f8c:	22010113          	addi	sp,sp,544
    80004f90:	8082                	ret
    end_op();
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	476080e7          	jalr	1142(ra) # 80004408 <end_op>
    return -1;
    80004f9a:	557d                	li	a0,-1
    80004f9c:	b7f9                	j	80004f6a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	ad0080e7          	jalr	-1328(ra) # 80001a70 <proc_pagetable>
    80004fa8:	8b2a                	mv	s6,a0
    80004faa:	d555                	beqz	a0,80004f56 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fac:	e7042783          	lw	a5,-400(s0)
    80004fb0:	e8845703          	lhu	a4,-376(s0)
    80004fb4:	c735                	beqz	a4,80005020 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fb6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fbc:	6a05                	lui	s4,0x1
    80004fbe:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fc2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004fc6:	6d85                	lui	s11,0x1
    80004fc8:	7d7d                	lui	s10,0xfffff
    80004fca:	a481                	j	8000520a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fcc:	00003517          	auipc	a0,0x3
    80004fd0:	72450513          	addi	a0,a0,1828 # 800086f0 <syscalls+0x2a0>
    80004fd4:	ffffb097          	auipc	ra,0xffffb
    80004fd8:	56a080e7          	jalr	1386(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fdc:	874a                	mv	a4,s2
    80004fde:	009c86bb          	addw	a3,s9,s1
    80004fe2:	4581                	li	a1,0
    80004fe4:	8556                	mv	a0,s5
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	c94080e7          	jalr	-876(ra) # 80003c7a <readi>
    80004fee:	2501                	sext.w	a0,a0
    80004ff0:	1aa91a63          	bne	s2,a0,800051a4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ff4:	009d84bb          	addw	s1,s11,s1
    80004ff8:	013d09bb          	addw	s3,s10,s3
    80004ffc:	1f74f763          	bgeu	s1,s7,800051ea <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005000:	02049593          	slli	a1,s1,0x20
    80005004:	9181                	srli	a1,a1,0x20
    80005006:	95e2                	add	a1,a1,s8
    80005008:	855a                	mv	a0,s6
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	052080e7          	jalr	82(ra) # 8000105c <walkaddr>
    80005012:	862a                	mv	a2,a0
    if(pa == 0)
    80005014:	dd45                	beqz	a0,80004fcc <exec+0xfe>
      n = PGSIZE;
    80005016:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005018:	fd49f2e3          	bgeu	s3,s4,80004fdc <exec+0x10e>
      n = sz - i;
    8000501c:	894e                	mv	s2,s3
    8000501e:	bf7d                	j	80004fdc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005020:	4901                	li	s2,0
  iunlockput(ip);
    80005022:	8556                	mv	a0,s5
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	c04080e7          	jalr	-1020(ra) # 80003c28 <iunlockput>
  end_op();
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	3dc080e7          	jalr	988(ra) # 80004408 <end_op>
  p = myproc();
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	978080e7          	jalr	-1672(ra) # 800019ac <myproc>
    8000503c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000503e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005042:	6785                	lui	a5,0x1
    80005044:	17fd                	addi	a5,a5,-1
    80005046:	993e                	add	s2,s2,a5
    80005048:	77fd                	lui	a5,0xfffff
    8000504a:	00f977b3          	and	a5,s2,a5
    8000504e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005052:	4691                	li	a3,4
    80005054:	6609                	lui	a2,0x2
    80005056:	963e                	add	a2,a2,a5
    80005058:	85be                	mv	a1,a5
    8000505a:	855a                	mv	a0,s6
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	3b4080e7          	jalr	948(ra) # 80001410 <uvmalloc>
    80005064:	8c2a                	mv	s8,a0
  ip = 0;
    80005066:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005068:	12050e63          	beqz	a0,800051a4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000506c:	75f9                	lui	a1,0xffffe
    8000506e:	95aa                	add	a1,a1,a0
    80005070:	855a                	mv	a0,s6
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	5c4080e7          	jalr	1476(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    8000507a:	7afd                	lui	s5,0xfffff
    8000507c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000507e:	df043783          	ld	a5,-528(s0)
    80005082:	6388                	ld	a0,0(a5)
    80005084:	c925                	beqz	a0,800050f4 <exec+0x226>
    80005086:	e9040993          	addi	s3,s0,-368
    8000508a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000508e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005090:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	dbc080e7          	jalr	-580(ra) # 80000e4e <strlen>
    8000509a:	0015079b          	addiw	a5,a0,1
    8000509e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050a2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050a6:	13596663          	bltu	s2,s5,800051d2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050aa:	df043d83          	ld	s11,-528(s0)
    800050ae:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050b2:	8552                	mv	a0,s4
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	d9a080e7          	jalr	-614(ra) # 80000e4e <strlen>
    800050bc:	0015069b          	addiw	a3,a0,1
    800050c0:	8652                	mv	a2,s4
    800050c2:	85ca                	mv	a1,s2
    800050c4:	855a                	mv	a0,s6
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	5a2080e7          	jalr	1442(ra) # 80001668 <copyout>
    800050ce:	10054663          	bltz	a0,800051da <exec+0x30c>
    ustack[argc] = sp;
    800050d2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050d6:	0485                	addi	s1,s1,1
    800050d8:	008d8793          	addi	a5,s11,8
    800050dc:	def43823          	sd	a5,-528(s0)
    800050e0:	008db503          	ld	a0,8(s11)
    800050e4:	c911                	beqz	a0,800050f8 <exec+0x22a>
    if(argc >= MAXARG)
    800050e6:	09a1                	addi	s3,s3,8
    800050e8:	fb3c95e3          	bne	s9,s3,80005092 <exec+0x1c4>
  sz = sz1;
    800050ec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f0:	4a81                	li	s5,0
    800050f2:	a84d                	j	800051a4 <exec+0x2d6>
  sp = sz;
    800050f4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050f6:	4481                	li	s1,0
  ustack[argc] = 0;
    800050f8:	00349793          	slli	a5,s1,0x3
    800050fc:	f9040713          	addi	a4,s0,-112
    80005100:	97ba                	add	a5,a5,a4
    80005102:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc5a0>
  sp -= (argc+1) * sizeof(uint64);
    80005106:	00148693          	addi	a3,s1,1
    8000510a:	068e                	slli	a3,a3,0x3
    8000510c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005110:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005114:	01597663          	bgeu	s2,s5,80005120 <exec+0x252>
  sz = sz1;
    80005118:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511c:	4a81                	li	s5,0
    8000511e:	a059                	j	800051a4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005120:	e9040613          	addi	a2,s0,-368
    80005124:	85ca                	mv	a1,s2
    80005126:	855a                	mv	a0,s6
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	540080e7          	jalr	1344(ra) # 80001668 <copyout>
    80005130:	0a054963          	bltz	a0,800051e2 <exec+0x314>
  p->trapframe->a1 = sp;
    80005134:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    80005138:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000513c:	de843783          	ld	a5,-536(s0)
    80005140:	0007c703          	lbu	a4,0(a5)
    80005144:	cf11                	beqz	a4,80005160 <exec+0x292>
    80005146:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005148:	02f00693          	li	a3,47
    8000514c:	a039                	j	8000515a <exec+0x28c>
      last = s+1;
    8000514e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005152:	0785                	addi	a5,a5,1
    80005154:	fff7c703          	lbu	a4,-1(a5)
    80005158:	c701                	beqz	a4,80005160 <exec+0x292>
    if(*s == '/')
    8000515a:	fed71ce3          	bne	a4,a3,80005152 <exec+0x284>
    8000515e:	bfc5                	j	8000514e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005160:	4641                	li	a2,16
    80005162:	de843583          	ld	a1,-536(s0)
    80005166:	178b8513          	addi	a0,s7,376
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	cb2080e7          	jalr	-846(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005172:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005176:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    8000517a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000517e:	060bb783          	ld	a5,96(s7)
    80005182:	e6843703          	ld	a4,-408(s0)
    80005186:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005188:	060bb783          	ld	a5,96(s7)
    8000518c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005190:	85ea                	mv	a1,s10
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	97a080e7          	jalr	-1670(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000519a:	0004851b          	sext.w	a0,s1
    8000519e:	b3f1                	j	80004f6a <exec+0x9c>
    800051a0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051a4:	df843583          	ld	a1,-520(s0)
    800051a8:	855a                	mv	a0,s6
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	962080e7          	jalr	-1694(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051b2:	da0a92e3          	bnez	s5,80004f56 <exec+0x88>
  return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	bb4d                	j	80004f6a <exec+0x9c>
    800051ba:	df243c23          	sd	s2,-520(s0)
    800051be:	b7dd                	j	800051a4 <exec+0x2d6>
    800051c0:	df243c23          	sd	s2,-520(s0)
    800051c4:	b7c5                	j	800051a4 <exec+0x2d6>
    800051c6:	df243c23          	sd	s2,-520(s0)
    800051ca:	bfe9                	j	800051a4 <exec+0x2d6>
    800051cc:	df243c23          	sd	s2,-520(s0)
    800051d0:	bfd1                	j	800051a4 <exec+0x2d6>
  sz = sz1;
    800051d2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051d6:	4a81                	li	s5,0
    800051d8:	b7f1                	j	800051a4 <exec+0x2d6>
  sz = sz1;
    800051da:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051de:	4a81                	li	s5,0
    800051e0:	b7d1                	j	800051a4 <exec+0x2d6>
  sz = sz1;
    800051e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051e6:	4a81                	li	s5,0
    800051e8:	bf75                	j	800051a4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051ea:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ee:	e0843783          	ld	a5,-504(s0)
    800051f2:	0017869b          	addiw	a3,a5,1
    800051f6:	e0d43423          	sd	a3,-504(s0)
    800051fa:	e0043783          	ld	a5,-512(s0)
    800051fe:	0387879b          	addiw	a5,a5,56
    80005202:	e8845703          	lhu	a4,-376(s0)
    80005206:	e0e6dee3          	bge	a3,a4,80005022 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000520a:	2781                	sext.w	a5,a5
    8000520c:	e0f43023          	sd	a5,-512(s0)
    80005210:	03800713          	li	a4,56
    80005214:	86be                	mv	a3,a5
    80005216:	e1840613          	addi	a2,s0,-488
    8000521a:	4581                	li	a1,0
    8000521c:	8556                	mv	a0,s5
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	a5c080e7          	jalr	-1444(ra) # 80003c7a <readi>
    80005226:	03800793          	li	a5,56
    8000522a:	f6f51be3          	bne	a0,a5,800051a0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000522e:	e1842783          	lw	a5,-488(s0)
    80005232:	4705                	li	a4,1
    80005234:	fae79de3          	bne	a5,a4,800051ee <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005238:	e4043483          	ld	s1,-448(s0)
    8000523c:	e3843783          	ld	a5,-456(s0)
    80005240:	f6f4ede3          	bltu	s1,a5,800051ba <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005244:	e2843783          	ld	a5,-472(s0)
    80005248:	94be                	add	s1,s1,a5
    8000524a:	f6f4ebe3          	bltu	s1,a5,800051c0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000524e:	de043703          	ld	a4,-544(s0)
    80005252:	8ff9                	and	a5,a5,a4
    80005254:	fbad                	bnez	a5,800051c6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005256:	e1c42503          	lw	a0,-484(s0)
    8000525a:	00000097          	auipc	ra,0x0
    8000525e:	c58080e7          	jalr	-936(ra) # 80004eb2 <flags2perm>
    80005262:	86aa                	mv	a3,a0
    80005264:	8626                	mv	a2,s1
    80005266:	85ca                	mv	a1,s2
    80005268:	855a                	mv	a0,s6
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	1a6080e7          	jalr	422(ra) # 80001410 <uvmalloc>
    80005272:	dea43c23          	sd	a0,-520(s0)
    80005276:	d939                	beqz	a0,800051cc <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005278:	e2843c03          	ld	s8,-472(s0)
    8000527c:	e2042c83          	lw	s9,-480(s0)
    80005280:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005284:	f60b83e3          	beqz	s7,800051ea <exec+0x31c>
    80005288:	89de                	mv	s3,s7
    8000528a:	4481                	li	s1,0
    8000528c:	bb95                	j	80005000 <exec+0x132>

000000008000528e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000528e:	7179                	addi	sp,sp,-48
    80005290:	f406                	sd	ra,40(sp)
    80005292:	f022                	sd	s0,32(sp)
    80005294:	ec26                	sd	s1,24(sp)
    80005296:	e84a                	sd	s2,16(sp)
    80005298:	1800                	addi	s0,sp,48
    8000529a:	892e                	mv	s2,a1
    8000529c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000529e:	fdc40593          	addi	a1,s0,-36
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	a58080e7          	jalr	-1448(ra) # 80002cfa <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052aa:	fdc42703          	lw	a4,-36(s0)
    800052ae:	47bd                	li	a5,15
    800052b0:	02e7eb63          	bltu	a5,a4,800052e6 <argfd+0x58>
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	6f8080e7          	jalr	1784(ra) # 800019ac <myproc>
    800052bc:	fdc42703          	lw	a4,-36(s0)
    800052c0:	01e70793          	addi	a5,a4,30
    800052c4:	078e                	slli	a5,a5,0x3
    800052c6:	953e                	add	a0,a0,a5
    800052c8:	611c                	ld	a5,0(a0)
    800052ca:	c385                	beqz	a5,800052ea <argfd+0x5c>
    return -1;
  if(pfd)
    800052cc:	00090463          	beqz	s2,800052d4 <argfd+0x46>
    *pfd = fd;
    800052d0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052d4:	4501                	li	a0,0
  if(pf)
    800052d6:	c091                	beqz	s1,800052da <argfd+0x4c>
    *pf = f;
    800052d8:	e09c                	sd	a5,0(s1)
}
    800052da:	70a2                	ld	ra,40(sp)
    800052dc:	7402                	ld	s0,32(sp)
    800052de:	64e2                	ld	s1,24(sp)
    800052e0:	6942                	ld	s2,16(sp)
    800052e2:	6145                	addi	sp,sp,48
    800052e4:	8082                	ret
    return -1;
    800052e6:	557d                	li	a0,-1
    800052e8:	bfcd                	j	800052da <argfd+0x4c>
    800052ea:	557d                	li	a0,-1
    800052ec:	b7fd                	j	800052da <argfd+0x4c>

00000000800052ee <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ee:	1101                	addi	sp,sp,-32
    800052f0:	ec06                	sd	ra,24(sp)
    800052f2:	e822                	sd	s0,16(sp)
    800052f4:	e426                	sd	s1,8(sp)
    800052f6:	1000                	addi	s0,sp,32
    800052f8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	6b2080e7          	jalr	1714(ra) # 800019ac <myproc>
    80005302:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005304:	0f050793          	addi	a5,a0,240
    80005308:	4501                	li	a0,0
    8000530a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000530c:	6398                	ld	a4,0(a5)
    8000530e:	cb19                	beqz	a4,80005324 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005310:	2505                	addiw	a0,a0,1
    80005312:	07a1                	addi	a5,a5,8
    80005314:	fed51ce3          	bne	a0,a3,8000530c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005318:	557d                	li	a0,-1
}
    8000531a:	60e2                	ld	ra,24(sp)
    8000531c:	6442                	ld	s0,16(sp)
    8000531e:	64a2                	ld	s1,8(sp)
    80005320:	6105                	addi	sp,sp,32
    80005322:	8082                	ret
      p->ofile[fd] = f;
    80005324:	01e50793          	addi	a5,a0,30
    80005328:	078e                	slli	a5,a5,0x3
    8000532a:	963e                	add	a2,a2,a5
    8000532c:	e204                	sd	s1,0(a2)
      return fd;
    8000532e:	b7f5                	j	8000531a <fdalloc+0x2c>

0000000080005330 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005330:	715d                	addi	sp,sp,-80
    80005332:	e486                	sd	ra,72(sp)
    80005334:	e0a2                	sd	s0,64(sp)
    80005336:	fc26                	sd	s1,56(sp)
    80005338:	f84a                	sd	s2,48(sp)
    8000533a:	f44e                	sd	s3,40(sp)
    8000533c:	f052                	sd	s4,32(sp)
    8000533e:	ec56                	sd	s5,24(sp)
    80005340:	e85a                	sd	s6,16(sp)
    80005342:	0880                	addi	s0,sp,80
    80005344:	8b2e                	mv	s6,a1
    80005346:	89b2                	mv	s3,a2
    80005348:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000534a:	fb040593          	addi	a1,s0,-80
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	e3c080e7          	jalr	-452(ra) # 8000418a <nameiparent>
    80005356:	84aa                	mv	s1,a0
    80005358:	14050f63          	beqz	a0,800054b6 <create+0x186>
    return 0;

  ilock(dp);
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	66a080e7          	jalr	1642(ra) # 800039c6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005364:	4601                	li	a2,0
    80005366:	fb040593          	addi	a1,s0,-80
    8000536a:	8526                	mv	a0,s1
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	b3e080e7          	jalr	-1218(ra) # 80003eaa <dirlookup>
    80005374:	8aaa                	mv	s5,a0
    80005376:	c931                	beqz	a0,800053ca <create+0x9a>
    iunlockput(dp);
    80005378:	8526                	mv	a0,s1
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	8ae080e7          	jalr	-1874(ra) # 80003c28 <iunlockput>
    ilock(ip);
    80005382:	8556                	mv	a0,s5
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	642080e7          	jalr	1602(ra) # 800039c6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000538c:	000b059b          	sext.w	a1,s6
    80005390:	4789                	li	a5,2
    80005392:	02f59563          	bne	a1,a5,800053bc <create+0x8c>
    80005396:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6e4>
    8000539a:	37f9                	addiw	a5,a5,-2
    8000539c:	17c2                	slli	a5,a5,0x30
    8000539e:	93c1                	srli	a5,a5,0x30
    800053a0:	4705                	li	a4,1
    800053a2:	00f76d63          	bltu	a4,a5,800053bc <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053a6:	8556                	mv	a0,s5
    800053a8:	60a6                	ld	ra,72(sp)
    800053aa:	6406                	ld	s0,64(sp)
    800053ac:	74e2                	ld	s1,56(sp)
    800053ae:	7942                	ld	s2,48(sp)
    800053b0:	79a2                	ld	s3,40(sp)
    800053b2:	7a02                	ld	s4,32(sp)
    800053b4:	6ae2                	ld	s5,24(sp)
    800053b6:	6b42                	ld	s6,16(sp)
    800053b8:	6161                	addi	sp,sp,80
    800053ba:	8082                	ret
    iunlockput(ip);
    800053bc:	8556                	mv	a0,s5
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	86a080e7          	jalr	-1942(ra) # 80003c28 <iunlockput>
    return 0;
    800053c6:	4a81                	li	s5,0
    800053c8:	bff9                	j	800053a6 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053ca:	85da                	mv	a1,s6
    800053cc:	4088                	lw	a0,0(s1)
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	45c080e7          	jalr	1116(ra) # 8000382a <ialloc>
    800053d6:	8a2a                	mv	s4,a0
    800053d8:	c539                	beqz	a0,80005426 <create+0xf6>
  ilock(ip);
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	5ec080e7          	jalr	1516(ra) # 800039c6 <ilock>
  ip->major = major;
    800053e2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053e6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053ea:	4905                	li	s2,1
    800053ec:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800053f0:	8552                	mv	a0,s4
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	50a080e7          	jalr	1290(ra) # 800038fc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053fa:	000b059b          	sext.w	a1,s6
    800053fe:	03258b63          	beq	a1,s2,80005434 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005402:	004a2603          	lw	a2,4(s4)
    80005406:	fb040593          	addi	a1,s0,-80
    8000540a:	8526                	mv	a0,s1
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	cae080e7          	jalr	-850(ra) # 800040ba <dirlink>
    80005414:	06054f63          	bltz	a0,80005492 <create+0x162>
  iunlockput(dp);
    80005418:	8526                	mv	a0,s1
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	80e080e7          	jalr	-2034(ra) # 80003c28 <iunlockput>
  return ip;
    80005422:	8ad2                	mv	s5,s4
    80005424:	b749                	j	800053a6 <create+0x76>
    iunlockput(dp);
    80005426:	8526                	mv	a0,s1
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	800080e7          	jalr	-2048(ra) # 80003c28 <iunlockput>
    return 0;
    80005430:	8ad2                	mv	s5,s4
    80005432:	bf95                	j	800053a6 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005434:	004a2603          	lw	a2,4(s4)
    80005438:	00003597          	auipc	a1,0x3
    8000543c:	2d858593          	addi	a1,a1,728 # 80008710 <syscalls+0x2c0>
    80005440:	8552                	mv	a0,s4
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	c78080e7          	jalr	-904(ra) # 800040ba <dirlink>
    8000544a:	04054463          	bltz	a0,80005492 <create+0x162>
    8000544e:	40d0                	lw	a2,4(s1)
    80005450:	00003597          	auipc	a1,0x3
    80005454:	2c858593          	addi	a1,a1,712 # 80008718 <syscalls+0x2c8>
    80005458:	8552                	mv	a0,s4
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	c60080e7          	jalr	-928(ra) # 800040ba <dirlink>
    80005462:	02054863          	bltz	a0,80005492 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005466:	004a2603          	lw	a2,4(s4)
    8000546a:	fb040593          	addi	a1,s0,-80
    8000546e:	8526                	mv	a0,s1
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	c4a080e7          	jalr	-950(ra) # 800040ba <dirlink>
    80005478:	00054d63          	bltz	a0,80005492 <create+0x162>
    dp->nlink++;  // for ".."
    8000547c:	04a4d783          	lhu	a5,74(s1)
    80005480:	2785                	addiw	a5,a5,1
    80005482:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	474080e7          	jalr	1140(ra) # 800038fc <iupdate>
    80005490:	b761                	j	80005418 <create+0xe8>
  ip->nlink = 0;
    80005492:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005496:	8552                	mv	a0,s4
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	464080e7          	jalr	1124(ra) # 800038fc <iupdate>
  iunlockput(ip);
    800054a0:	8552                	mv	a0,s4
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	786080e7          	jalr	1926(ra) # 80003c28 <iunlockput>
  iunlockput(dp);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	77c080e7          	jalr	1916(ra) # 80003c28 <iunlockput>
  return 0;
    800054b4:	bdcd                	j	800053a6 <create+0x76>
    return 0;
    800054b6:	8aaa                	mv	s5,a0
    800054b8:	b5fd                	j	800053a6 <create+0x76>

00000000800054ba <sys_dup>:
{
    800054ba:	7179                	addi	sp,sp,-48
    800054bc:	f406                	sd	ra,40(sp)
    800054be:	f022                	sd	s0,32(sp)
    800054c0:	ec26                	sd	s1,24(sp)
    800054c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054c4:	fd840613          	addi	a2,s0,-40
    800054c8:	4581                	li	a1,0
    800054ca:	4501                	li	a0,0
    800054cc:	00000097          	auipc	ra,0x0
    800054d0:	dc2080e7          	jalr	-574(ra) # 8000528e <argfd>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054d6:	02054363          	bltz	a0,800054fc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054da:	fd843503          	ld	a0,-40(s0)
    800054de:	00000097          	auipc	ra,0x0
    800054e2:	e10080e7          	jalr	-496(ra) # 800052ee <fdalloc>
    800054e6:	84aa                	mv	s1,a0
    return -1;
    800054e8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054ea:	00054963          	bltz	a0,800054fc <sys_dup+0x42>
  filedup(f);
    800054ee:	fd843503          	ld	a0,-40(s0)
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	310080e7          	jalr	784(ra) # 80004802 <filedup>
  return fd;
    800054fa:	87a6                	mv	a5,s1
}
    800054fc:	853e                	mv	a0,a5
    800054fe:	70a2                	ld	ra,40(sp)
    80005500:	7402                	ld	s0,32(sp)
    80005502:	64e2                	ld	s1,24(sp)
    80005504:	6145                	addi	sp,sp,48
    80005506:	8082                	ret

0000000080005508 <sys_read>:
{
    80005508:	7179                	addi	sp,sp,-48
    8000550a:	f406                	sd	ra,40(sp)
    8000550c:	f022                	sd	s0,32(sp)
    8000550e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005510:	fd840593          	addi	a1,s0,-40
    80005514:	4505                	li	a0,1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	804080e7          	jalr	-2044(ra) # 80002d1a <argaddr>
  argint(2, &n);
    8000551e:	fe440593          	addi	a1,s0,-28
    80005522:	4509                	li	a0,2
    80005524:	ffffd097          	auipc	ra,0xffffd
    80005528:	7d6080e7          	jalr	2006(ra) # 80002cfa <argint>
  if(argfd(0, 0, &f) < 0)
    8000552c:	fe840613          	addi	a2,s0,-24
    80005530:	4581                	li	a1,0
    80005532:	4501                	li	a0,0
    80005534:	00000097          	auipc	ra,0x0
    80005538:	d5a080e7          	jalr	-678(ra) # 8000528e <argfd>
    8000553c:	87aa                	mv	a5,a0
    return -1;
    8000553e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005540:	0007cc63          	bltz	a5,80005558 <sys_read+0x50>
  return fileread(f, p, n);
    80005544:	fe442603          	lw	a2,-28(s0)
    80005548:	fd843583          	ld	a1,-40(s0)
    8000554c:	fe843503          	ld	a0,-24(s0)
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	43e080e7          	jalr	1086(ra) # 8000498e <fileread>
}
    80005558:	70a2                	ld	ra,40(sp)
    8000555a:	7402                	ld	s0,32(sp)
    8000555c:	6145                	addi	sp,sp,48
    8000555e:	8082                	ret

0000000080005560 <sys_write>:
{
    80005560:	7179                	addi	sp,sp,-48
    80005562:	f406                	sd	ra,40(sp)
    80005564:	f022                	sd	s0,32(sp)
    80005566:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005568:	fd840593          	addi	a1,s0,-40
    8000556c:	4505                	li	a0,1
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	7ac080e7          	jalr	1964(ra) # 80002d1a <argaddr>
  argint(2, &n);
    80005576:	fe440593          	addi	a1,s0,-28
    8000557a:	4509                	li	a0,2
    8000557c:	ffffd097          	auipc	ra,0xffffd
    80005580:	77e080e7          	jalr	1918(ra) # 80002cfa <argint>
  if(argfd(0, 0, &f) < 0)
    80005584:	fe840613          	addi	a2,s0,-24
    80005588:	4581                	li	a1,0
    8000558a:	4501                	li	a0,0
    8000558c:	00000097          	auipc	ra,0x0
    80005590:	d02080e7          	jalr	-766(ra) # 8000528e <argfd>
    80005594:	87aa                	mv	a5,a0
    return -1;
    80005596:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005598:	0007cc63          	bltz	a5,800055b0 <sys_write+0x50>
  return filewrite(f, p, n);
    8000559c:	fe442603          	lw	a2,-28(s0)
    800055a0:	fd843583          	ld	a1,-40(s0)
    800055a4:	fe843503          	ld	a0,-24(s0)
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	4a8080e7          	jalr	1192(ra) # 80004a50 <filewrite>
}
    800055b0:	70a2                	ld	ra,40(sp)
    800055b2:	7402                	ld	s0,32(sp)
    800055b4:	6145                	addi	sp,sp,48
    800055b6:	8082                	ret

00000000800055b8 <sys_close>:
{
    800055b8:	1101                	addi	sp,sp,-32
    800055ba:	ec06                	sd	ra,24(sp)
    800055bc:	e822                	sd	s0,16(sp)
    800055be:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055c0:	fe040613          	addi	a2,s0,-32
    800055c4:	fec40593          	addi	a1,s0,-20
    800055c8:	4501                	li	a0,0
    800055ca:	00000097          	auipc	ra,0x0
    800055ce:	cc4080e7          	jalr	-828(ra) # 8000528e <argfd>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055d4:	02054463          	bltz	a0,800055fc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055d8:	ffffc097          	auipc	ra,0xffffc
    800055dc:	3d4080e7          	jalr	980(ra) # 800019ac <myproc>
    800055e0:	fec42783          	lw	a5,-20(s0)
    800055e4:	07f9                	addi	a5,a5,30
    800055e6:	078e                	slli	a5,a5,0x3
    800055e8:	97aa                	add	a5,a5,a0
    800055ea:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055ee:	fe043503          	ld	a0,-32(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	262080e7          	jalr	610(ra) # 80004854 <fileclose>
  return 0;
    800055fa:	4781                	li	a5,0
}
    800055fc:	853e                	mv	a0,a5
    800055fe:	60e2                	ld	ra,24(sp)
    80005600:	6442                	ld	s0,16(sp)
    80005602:	6105                	addi	sp,sp,32
    80005604:	8082                	ret

0000000080005606 <sys_fstat>:
{
    80005606:	1101                	addi	sp,sp,-32
    80005608:	ec06                	sd	ra,24(sp)
    8000560a:	e822                	sd	s0,16(sp)
    8000560c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000560e:	fe040593          	addi	a1,s0,-32
    80005612:	4505                	li	a0,1
    80005614:	ffffd097          	auipc	ra,0xffffd
    80005618:	706080e7          	jalr	1798(ra) # 80002d1a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000561c:	fe840613          	addi	a2,s0,-24
    80005620:	4581                	li	a1,0
    80005622:	4501                	li	a0,0
    80005624:	00000097          	auipc	ra,0x0
    80005628:	c6a080e7          	jalr	-918(ra) # 8000528e <argfd>
    8000562c:	87aa                	mv	a5,a0
    return -1;
    8000562e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005630:	0007ca63          	bltz	a5,80005644 <sys_fstat+0x3e>
  return filestat(f, st);
    80005634:	fe043583          	ld	a1,-32(s0)
    80005638:	fe843503          	ld	a0,-24(s0)
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	2e0080e7          	jalr	736(ra) # 8000491c <filestat>
}
    80005644:	60e2                	ld	ra,24(sp)
    80005646:	6442                	ld	s0,16(sp)
    80005648:	6105                	addi	sp,sp,32
    8000564a:	8082                	ret

000000008000564c <sys_link>:
{
    8000564c:	7169                	addi	sp,sp,-304
    8000564e:	f606                	sd	ra,296(sp)
    80005650:	f222                	sd	s0,288(sp)
    80005652:	ee26                	sd	s1,280(sp)
    80005654:	ea4a                	sd	s2,272(sp)
    80005656:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005658:	08000613          	li	a2,128
    8000565c:	ed040593          	addi	a1,s0,-304
    80005660:	4501                	li	a0,0
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	6d8080e7          	jalr	1752(ra) # 80002d3a <argstr>
    return -1;
    8000566a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000566c:	10054e63          	bltz	a0,80005788 <sys_link+0x13c>
    80005670:	08000613          	li	a2,128
    80005674:	f5040593          	addi	a1,s0,-176
    80005678:	4505                	li	a0,1
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	6c0080e7          	jalr	1728(ra) # 80002d3a <argstr>
    return -1;
    80005682:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005684:	10054263          	bltz	a0,80005788 <sys_link+0x13c>
  begin_op();
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	d00080e7          	jalr	-768(ra) # 80004388 <begin_op>
  if((ip = namei(old)) == 0){
    80005690:	ed040513          	addi	a0,s0,-304
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	ad8080e7          	jalr	-1320(ra) # 8000416c <namei>
    8000569c:	84aa                	mv	s1,a0
    8000569e:	c551                	beqz	a0,8000572a <sys_link+0xde>
  ilock(ip);
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	326080e7          	jalr	806(ra) # 800039c6 <ilock>
  if(ip->type == T_DIR){
    800056a8:	04449703          	lh	a4,68(s1)
    800056ac:	4785                	li	a5,1
    800056ae:	08f70463          	beq	a4,a5,80005736 <sys_link+0xea>
  ip->nlink++;
    800056b2:	04a4d783          	lhu	a5,74(s1)
    800056b6:	2785                	addiw	a5,a5,1
    800056b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	23e080e7          	jalr	574(ra) # 800038fc <iupdate>
  iunlock(ip);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	3c0080e7          	jalr	960(ra) # 80003a88 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056d0:	fd040593          	addi	a1,s0,-48
    800056d4:	f5040513          	addi	a0,s0,-176
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	ab2080e7          	jalr	-1358(ra) # 8000418a <nameiparent>
    800056e0:	892a                	mv	s2,a0
    800056e2:	c935                	beqz	a0,80005756 <sys_link+0x10a>
  ilock(dp);
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	2e2080e7          	jalr	738(ra) # 800039c6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ec:	00092703          	lw	a4,0(s2)
    800056f0:	409c                	lw	a5,0(s1)
    800056f2:	04f71d63          	bne	a4,a5,8000574c <sys_link+0x100>
    800056f6:	40d0                	lw	a2,4(s1)
    800056f8:	fd040593          	addi	a1,s0,-48
    800056fc:	854a                	mv	a0,s2
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	9bc080e7          	jalr	-1604(ra) # 800040ba <dirlink>
    80005706:	04054363          	bltz	a0,8000574c <sys_link+0x100>
  iunlockput(dp);
    8000570a:	854a                	mv	a0,s2
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	51c080e7          	jalr	1308(ra) # 80003c28 <iunlockput>
  iput(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	46a080e7          	jalr	1130(ra) # 80003b80 <iput>
  end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	cea080e7          	jalr	-790(ra) # 80004408 <end_op>
  return 0;
    80005726:	4781                	li	a5,0
    80005728:	a085                	j	80005788 <sys_link+0x13c>
    end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	cde080e7          	jalr	-802(ra) # 80004408 <end_op>
    return -1;
    80005732:	57fd                	li	a5,-1
    80005734:	a891                	j	80005788 <sys_link+0x13c>
    iunlockput(ip);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	4f0080e7          	jalr	1264(ra) # 80003c28 <iunlockput>
    end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	cc8080e7          	jalr	-824(ra) # 80004408 <end_op>
    return -1;
    80005748:	57fd                	li	a5,-1
    8000574a:	a83d                	j	80005788 <sys_link+0x13c>
    iunlockput(dp);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	4da080e7          	jalr	1242(ra) # 80003c28 <iunlockput>
  ilock(ip);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	26e080e7          	jalr	622(ra) # 800039c6 <ilock>
  ip->nlink--;
    80005760:	04a4d783          	lhu	a5,74(s1)
    80005764:	37fd                	addiw	a5,a5,-1
    80005766:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	190080e7          	jalr	400(ra) # 800038fc <iupdate>
  iunlockput(ip);
    80005774:	8526                	mv	a0,s1
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	4b2080e7          	jalr	1202(ra) # 80003c28 <iunlockput>
  end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	c8a080e7          	jalr	-886(ra) # 80004408 <end_op>
  return -1;
    80005786:	57fd                	li	a5,-1
}
    80005788:	853e                	mv	a0,a5
    8000578a:	70b2                	ld	ra,296(sp)
    8000578c:	7412                	ld	s0,288(sp)
    8000578e:	64f2                	ld	s1,280(sp)
    80005790:	6952                	ld	s2,272(sp)
    80005792:	6155                	addi	sp,sp,304
    80005794:	8082                	ret

0000000080005796 <sys_unlink>:
{
    80005796:	7151                	addi	sp,sp,-240
    80005798:	f586                	sd	ra,232(sp)
    8000579a:	f1a2                	sd	s0,224(sp)
    8000579c:	eda6                	sd	s1,216(sp)
    8000579e:	e9ca                	sd	s2,208(sp)
    800057a0:	e5ce                	sd	s3,200(sp)
    800057a2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057a4:	08000613          	li	a2,128
    800057a8:	f3040593          	addi	a1,s0,-208
    800057ac:	4501                	li	a0,0
    800057ae:	ffffd097          	auipc	ra,0xffffd
    800057b2:	58c080e7          	jalr	1420(ra) # 80002d3a <argstr>
    800057b6:	18054163          	bltz	a0,80005938 <sys_unlink+0x1a2>
  begin_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	bce080e7          	jalr	-1074(ra) # 80004388 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057c2:	fb040593          	addi	a1,s0,-80
    800057c6:	f3040513          	addi	a0,s0,-208
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	9c0080e7          	jalr	-1600(ra) # 8000418a <nameiparent>
    800057d2:	84aa                	mv	s1,a0
    800057d4:	c979                	beqz	a0,800058aa <sys_unlink+0x114>
  ilock(dp);
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	1f0080e7          	jalr	496(ra) # 800039c6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057de:	00003597          	auipc	a1,0x3
    800057e2:	f3258593          	addi	a1,a1,-206 # 80008710 <syscalls+0x2c0>
    800057e6:	fb040513          	addi	a0,s0,-80
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	6a6080e7          	jalr	1702(ra) # 80003e90 <namecmp>
    800057f2:	14050a63          	beqz	a0,80005946 <sys_unlink+0x1b0>
    800057f6:	00003597          	auipc	a1,0x3
    800057fa:	f2258593          	addi	a1,a1,-222 # 80008718 <syscalls+0x2c8>
    800057fe:	fb040513          	addi	a0,s0,-80
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	68e080e7          	jalr	1678(ra) # 80003e90 <namecmp>
    8000580a:	12050e63          	beqz	a0,80005946 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000580e:	f2c40613          	addi	a2,s0,-212
    80005812:	fb040593          	addi	a1,s0,-80
    80005816:	8526                	mv	a0,s1
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	692080e7          	jalr	1682(ra) # 80003eaa <dirlookup>
    80005820:	892a                	mv	s2,a0
    80005822:	12050263          	beqz	a0,80005946 <sys_unlink+0x1b0>
  ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	1a0080e7          	jalr	416(ra) # 800039c6 <ilock>
  if(ip->nlink < 1)
    8000582e:	04a91783          	lh	a5,74(s2)
    80005832:	08f05263          	blez	a5,800058b6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	4785                	li	a5,1
    8000583c:	08f70563          	beq	a4,a5,800058c6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005840:	4641                	li	a2,16
    80005842:	4581                	li	a1,0
    80005844:	fc040513          	addi	a0,s0,-64
    80005848:	ffffb097          	auipc	ra,0xffffb
    8000584c:	48a080e7          	jalr	1162(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005850:	4741                	li	a4,16
    80005852:	f2c42683          	lw	a3,-212(s0)
    80005856:	fc040613          	addi	a2,s0,-64
    8000585a:	4581                	li	a1,0
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	514080e7          	jalr	1300(ra) # 80003d72 <writei>
    80005866:	47c1                	li	a5,16
    80005868:	0af51563          	bne	a0,a5,80005912 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000586c:	04491703          	lh	a4,68(s2)
    80005870:	4785                	li	a5,1
    80005872:	0af70863          	beq	a4,a5,80005922 <sys_unlink+0x18c>
  iunlockput(dp);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	3b0080e7          	jalr	944(ra) # 80003c28 <iunlockput>
  ip->nlink--;
    80005880:	04a95783          	lhu	a5,74(s2)
    80005884:	37fd                	addiw	a5,a5,-1
    80005886:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	070080e7          	jalr	112(ra) # 800038fc <iupdate>
  iunlockput(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	392080e7          	jalr	914(ra) # 80003c28 <iunlockput>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	b6a080e7          	jalr	-1174(ra) # 80004408 <end_op>
  return 0;
    800058a6:	4501                	li	a0,0
    800058a8:	a84d                	j	8000595a <sys_unlink+0x1c4>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	b5e080e7          	jalr	-1186(ra) # 80004408 <end_op>
    return -1;
    800058b2:	557d                	li	a0,-1
    800058b4:	a05d                	j	8000595a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058b6:	00003517          	auipc	a0,0x3
    800058ba:	e6a50513          	addi	a0,a0,-406 # 80008720 <syscalls+0x2d0>
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c6:	04c92703          	lw	a4,76(s2)
    800058ca:	02000793          	li	a5,32
    800058ce:	f6e7f9e3          	bgeu	a5,a4,80005840 <sys_unlink+0xaa>
    800058d2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058d6:	4741                	li	a4,16
    800058d8:	86ce                	mv	a3,s3
    800058da:	f1840613          	addi	a2,s0,-232
    800058de:	4581                	li	a1,0
    800058e0:	854a                	mv	a0,s2
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	398080e7          	jalr	920(ra) # 80003c7a <readi>
    800058ea:	47c1                	li	a5,16
    800058ec:	00f51b63          	bne	a0,a5,80005902 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058f0:	f1845783          	lhu	a5,-232(s0)
    800058f4:	e7a1                	bnez	a5,8000593c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058f6:	29c1                	addiw	s3,s3,16
    800058f8:	04c92783          	lw	a5,76(s2)
    800058fc:	fcf9ede3          	bltu	s3,a5,800058d6 <sys_unlink+0x140>
    80005900:	b781                	j	80005840 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005902:	00003517          	auipc	a0,0x3
    80005906:	e3650513          	addi	a0,a0,-458 # 80008738 <syscalls+0x2e8>
    8000590a:	ffffb097          	auipc	ra,0xffffb
    8000590e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005912:	00003517          	auipc	a0,0x3
    80005916:	e3e50513          	addi	a0,a0,-450 # 80008750 <syscalls+0x300>
    8000591a:	ffffb097          	auipc	ra,0xffffb
    8000591e:	c24080e7          	jalr	-988(ra) # 8000053e <panic>
    dp->nlink--;
    80005922:	04a4d783          	lhu	a5,74(s1)
    80005926:	37fd                	addiw	a5,a5,-1
    80005928:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	fce080e7          	jalr	-50(ra) # 800038fc <iupdate>
    80005936:	b781                	j	80005876 <sys_unlink+0xe0>
    return -1;
    80005938:	557d                	li	a0,-1
    8000593a:	a005                	j	8000595a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000593c:	854a                	mv	a0,s2
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	2ea080e7          	jalr	746(ra) # 80003c28 <iunlockput>
  iunlockput(dp);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	2e0080e7          	jalr	736(ra) # 80003c28 <iunlockput>
  end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	ab8080e7          	jalr	-1352(ra) # 80004408 <end_op>
  return -1;
    80005958:	557d                	li	a0,-1
}
    8000595a:	70ae                	ld	ra,232(sp)
    8000595c:	740e                	ld	s0,224(sp)
    8000595e:	64ee                	ld	s1,216(sp)
    80005960:	694e                	ld	s2,208(sp)
    80005962:	69ae                	ld	s3,200(sp)
    80005964:	616d                	addi	sp,sp,240
    80005966:	8082                	ret

0000000080005968 <sys_open>:

uint64
sys_open(void)
{
    80005968:	7131                	addi	sp,sp,-192
    8000596a:	fd06                	sd	ra,184(sp)
    8000596c:	f922                	sd	s0,176(sp)
    8000596e:	f526                	sd	s1,168(sp)
    80005970:	f14a                	sd	s2,160(sp)
    80005972:	ed4e                	sd	s3,152(sp)
    80005974:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005976:	f4c40593          	addi	a1,s0,-180
    8000597a:	4505                	li	a0,1
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	37e080e7          	jalr	894(ra) # 80002cfa <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005984:	08000613          	li	a2,128
    80005988:	f5040593          	addi	a1,s0,-176
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	3ac080e7          	jalr	940(ra) # 80002d3a <argstr>
    80005996:	87aa                	mv	a5,a0
    return -1;
    80005998:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000599a:	0a07c963          	bltz	a5,80005a4c <sys_open+0xe4>

  begin_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	9ea080e7          	jalr	-1558(ra) # 80004388 <begin_op>

  if(omode & O_CREATE){
    800059a6:	f4c42783          	lw	a5,-180(s0)
    800059aa:	2007f793          	andi	a5,a5,512
    800059ae:	cfc5                	beqz	a5,80005a66 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059b0:	4681                	li	a3,0
    800059b2:	4601                	li	a2,0
    800059b4:	4589                	li	a1,2
    800059b6:	f5040513          	addi	a0,s0,-176
    800059ba:	00000097          	auipc	ra,0x0
    800059be:	976080e7          	jalr	-1674(ra) # 80005330 <create>
    800059c2:	84aa                	mv	s1,a0
    if(ip == 0){
    800059c4:	c959                	beqz	a0,80005a5a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059c6:	04449703          	lh	a4,68(s1)
    800059ca:	478d                	li	a5,3
    800059cc:	00f71763          	bne	a4,a5,800059da <sys_open+0x72>
    800059d0:	0464d703          	lhu	a4,70(s1)
    800059d4:	47a5                	li	a5,9
    800059d6:	0ce7ed63          	bltu	a5,a4,80005ab0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	dbe080e7          	jalr	-578(ra) # 80004798 <filealloc>
    800059e2:	89aa                	mv	s3,a0
    800059e4:	10050363          	beqz	a0,80005aea <sys_open+0x182>
    800059e8:	00000097          	auipc	ra,0x0
    800059ec:	906080e7          	jalr	-1786(ra) # 800052ee <fdalloc>
    800059f0:	892a                	mv	s2,a0
    800059f2:	0e054763          	bltz	a0,80005ae0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059f6:	04449703          	lh	a4,68(s1)
    800059fa:	478d                	li	a5,3
    800059fc:	0cf70563          	beq	a4,a5,80005ac6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a00:	4789                	li	a5,2
    80005a02:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a06:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a0a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a0e:	f4c42783          	lw	a5,-180(s0)
    80005a12:	0017c713          	xori	a4,a5,1
    80005a16:	8b05                	andi	a4,a4,1
    80005a18:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a1c:	0037f713          	andi	a4,a5,3
    80005a20:	00e03733          	snez	a4,a4
    80005a24:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a28:	4007f793          	andi	a5,a5,1024
    80005a2c:	c791                	beqz	a5,80005a38 <sys_open+0xd0>
    80005a2e:	04449703          	lh	a4,68(s1)
    80005a32:	4789                	li	a5,2
    80005a34:	0af70063          	beq	a4,a5,80005ad4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	04e080e7          	jalr	78(ra) # 80003a88 <iunlock>
  end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	9c6080e7          	jalr	-1594(ra) # 80004408 <end_op>

  return fd;
    80005a4a:	854a                	mv	a0,s2
}
    80005a4c:	70ea                	ld	ra,184(sp)
    80005a4e:	744a                	ld	s0,176(sp)
    80005a50:	74aa                	ld	s1,168(sp)
    80005a52:	790a                	ld	s2,160(sp)
    80005a54:	69ea                	ld	s3,152(sp)
    80005a56:	6129                	addi	sp,sp,192
    80005a58:	8082                	ret
      end_op();
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	9ae080e7          	jalr	-1618(ra) # 80004408 <end_op>
      return -1;
    80005a62:	557d                	li	a0,-1
    80005a64:	b7e5                	j	80005a4c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a66:	f5040513          	addi	a0,s0,-176
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	702080e7          	jalr	1794(ra) # 8000416c <namei>
    80005a72:	84aa                	mv	s1,a0
    80005a74:	c905                	beqz	a0,80005aa4 <sys_open+0x13c>
    ilock(ip);
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	f50080e7          	jalr	-176(ra) # 800039c6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a7e:	04449703          	lh	a4,68(s1)
    80005a82:	4785                	li	a5,1
    80005a84:	f4f711e3          	bne	a4,a5,800059c6 <sys_open+0x5e>
    80005a88:	f4c42783          	lw	a5,-180(s0)
    80005a8c:	d7b9                	beqz	a5,800059da <sys_open+0x72>
      iunlockput(ip);
    80005a8e:	8526                	mv	a0,s1
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	198080e7          	jalr	408(ra) # 80003c28 <iunlockput>
      end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	970080e7          	jalr	-1680(ra) # 80004408 <end_op>
      return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	b76d                	j	80005a4c <sys_open+0xe4>
      end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	964080e7          	jalr	-1692(ra) # 80004408 <end_op>
      return -1;
    80005aac:	557d                	li	a0,-1
    80005aae:	bf79                	j	80005a4c <sys_open+0xe4>
    iunlockput(ip);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	176080e7          	jalr	374(ra) # 80003c28 <iunlockput>
    end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	94e080e7          	jalr	-1714(ra) # 80004408 <end_op>
    return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	b761                	j	80005a4c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ac6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005aca:	04649783          	lh	a5,70(s1)
    80005ace:	02f99223          	sh	a5,36(s3)
    80005ad2:	bf25                	j	80005a0a <sys_open+0xa2>
    itrunc(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	ffe080e7          	jalr	-2(ra) # 80003ad4 <itrunc>
    80005ade:	bfa9                	j	80005a38 <sys_open+0xd0>
      fileclose(f);
    80005ae0:	854e                	mv	a0,s3
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	d72080e7          	jalr	-654(ra) # 80004854 <fileclose>
    iunlockput(ip);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	13c080e7          	jalr	316(ra) # 80003c28 <iunlockput>
    end_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	914080e7          	jalr	-1772(ra) # 80004408 <end_op>
    return -1;
    80005afc:	557d                	li	a0,-1
    80005afe:	b7b9                	j	80005a4c <sys_open+0xe4>

0000000080005b00 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b00:	7175                	addi	sp,sp,-144
    80005b02:	e506                	sd	ra,136(sp)
    80005b04:	e122                	sd	s0,128(sp)
    80005b06:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	880080e7          	jalr	-1920(ra) # 80004388 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b10:	08000613          	li	a2,128
    80005b14:	f7040593          	addi	a1,s0,-144
    80005b18:	4501                	li	a0,0
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	220080e7          	jalr	544(ra) # 80002d3a <argstr>
    80005b22:	02054963          	bltz	a0,80005b54 <sys_mkdir+0x54>
    80005b26:	4681                	li	a3,0
    80005b28:	4601                	li	a2,0
    80005b2a:	4585                	li	a1,1
    80005b2c:	f7040513          	addi	a0,s0,-144
    80005b30:	00000097          	auipc	ra,0x0
    80005b34:	800080e7          	jalr	-2048(ra) # 80005330 <create>
    80005b38:	cd11                	beqz	a0,80005b54 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	0ee080e7          	jalr	238(ra) # 80003c28 <iunlockput>
  end_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	8c6080e7          	jalr	-1850(ra) # 80004408 <end_op>
  return 0;
    80005b4a:	4501                	li	a0,0
}
    80005b4c:	60aa                	ld	ra,136(sp)
    80005b4e:	640a                	ld	s0,128(sp)
    80005b50:	6149                	addi	sp,sp,144
    80005b52:	8082                	ret
    end_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	8b4080e7          	jalr	-1868(ra) # 80004408 <end_op>
    return -1;
    80005b5c:	557d                	li	a0,-1
    80005b5e:	b7fd                	j	80005b4c <sys_mkdir+0x4c>

0000000080005b60 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b60:	7135                	addi	sp,sp,-160
    80005b62:	ed06                	sd	ra,152(sp)
    80005b64:	e922                	sd	s0,144(sp)
    80005b66:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	820080e7          	jalr	-2016(ra) # 80004388 <begin_op>
  argint(1, &major);
    80005b70:	f6c40593          	addi	a1,s0,-148
    80005b74:	4505                	li	a0,1
    80005b76:	ffffd097          	auipc	ra,0xffffd
    80005b7a:	184080e7          	jalr	388(ra) # 80002cfa <argint>
  argint(2, &minor);
    80005b7e:	f6840593          	addi	a1,s0,-152
    80005b82:	4509                	li	a0,2
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	176080e7          	jalr	374(ra) # 80002cfa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b8c:	08000613          	li	a2,128
    80005b90:	f7040593          	addi	a1,s0,-144
    80005b94:	4501                	li	a0,0
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	1a4080e7          	jalr	420(ra) # 80002d3a <argstr>
    80005b9e:	02054b63          	bltz	a0,80005bd4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ba2:	f6841683          	lh	a3,-152(s0)
    80005ba6:	f6c41603          	lh	a2,-148(s0)
    80005baa:	458d                	li	a1,3
    80005bac:	f7040513          	addi	a0,s0,-144
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	780080e7          	jalr	1920(ra) # 80005330 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb8:	cd11                	beqz	a0,80005bd4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	06e080e7          	jalr	110(ra) # 80003c28 <iunlockput>
  end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	846080e7          	jalr	-1978(ra) # 80004408 <end_op>
  return 0;
    80005bca:	4501                	li	a0,0
}
    80005bcc:	60ea                	ld	ra,152(sp)
    80005bce:	644a                	ld	s0,144(sp)
    80005bd0:	610d                	addi	sp,sp,160
    80005bd2:	8082                	ret
    end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	834080e7          	jalr	-1996(ra) # 80004408 <end_op>
    return -1;
    80005bdc:	557d                	li	a0,-1
    80005bde:	b7fd                	j	80005bcc <sys_mknod+0x6c>

0000000080005be0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005be0:	7135                	addi	sp,sp,-160
    80005be2:	ed06                	sd	ra,152(sp)
    80005be4:	e922                	sd	s0,144(sp)
    80005be6:	e526                	sd	s1,136(sp)
    80005be8:	e14a                	sd	s2,128(sp)
    80005bea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bec:	ffffc097          	auipc	ra,0xffffc
    80005bf0:	dc0080e7          	jalr	-576(ra) # 800019ac <myproc>
    80005bf4:	892a                	mv	s2,a0
  
  begin_op();
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	792080e7          	jalr	1938(ra) # 80004388 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bfe:	08000613          	li	a2,128
    80005c02:	f6040593          	addi	a1,s0,-160
    80005c06:	4501                	li	a0,0
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	132080e7          	jalr	306(ra) # 80002d3a <argstr>
    80005c10:	04054b63          	bltz	a0,80005c66 <sys_chdir+0x86>
    80005c14:	f6040513          	addi	a0,s0,-160
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	554080e7          	jalr	1364(ra) # 8000416c <namei>
    80005c20:	84aa                	mv	s1,a0
    80005c22:	c131                	beqz	a0,80005c66 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	da2080e7          	jalr	-606(ra) # 800039c6 <ilock>
  if(ip->type != T_DIR){
    80005c2c:	04449703          	lh	a4,68(s1)
    80005c30:	4785                	li	a5,1
    80005c32:	04f71063          	bne	a4,a5,80005c72 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c36:	8526                	mv	a0,s1
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	e50080e7          	jalr	-432(ra) # 80003a88 <iunlock>
  iput(p->cwd);
    80005c40:	17093503          	ld	a0,368(s2)
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	f3c080e7          	jalr	-196(ra) # 80003b80 <iput>
  end_op();
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	7bc080e7          	jalr	1980(ra) # 80004408 <end_op>
  p->cwd = ip;
    80005c54:	16993823          	sd	s1,368(s2)
  return 0;
    80005c58:	4501                	li	a0,0
}
    80005c5a:	60ea                	ld	ra,152(sp)
    80005c5c:	644a                	ld	s0,144(sp)
    80005c5e:	64aa                	ld	s1,136(sp)
    80005c60:	690a                	ld	s2,128(sp)
    80005c62:	610d                	addi	sp,sp,160
    80005c64:	8082                	ret
    end_op();
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	7a2080e7          	jalr	1954(ra) # 80004408 <end_op>
    return -1;
    80005c6e:	557d                	li	a0,-1
    80005c70:	b7ed                	j	80005c5a <sys_chdir+0x7a>
    iunlockput(ip);
    80005c72:	8526                	mv	a0,s1
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	fb4080e7          	jalr	-76(ra) # 80003c28 <iunlockput>
    end_op();
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	78c080e7          	jalr	1932(ra) # 80004408 <end_op>
    return -1;
    80005c84:	557d                	li	a0,-1
    80005c86:	bfd1                	j	80005c5a <sys_chdir+0x7a>

0000000080005c88 <sys_exec>:

uint64
sys_exec(void)
{
    80005c88:	7145                	addi	sp,sp,-464
    80005c8a:	e786                	sd	ra,456(sp)
    80005c8c:	e3a2                	sd	s0,448(sp)
    80005c8e:	ff26                	sd	s1,440(sp)
    80005c90:	fb4a                	sd	s2,432(sp)
    80005c92:	f74e                	sd	s3,424(sp)
    80005c94:	f352                	sd	s4,416(sp)
    80005c96:	ef56                	sd	s5,408(sp)
    80005c98:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c9a:	e3840593          	addi	a1,s0,-456
    80005c9e:	4505                	li	a0,1
    80005ca0:	ffffd097          	auipc	ra,0xffffd
    80005ca4:	07a080e7          	jalr	122(ra) # 80002d1a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ca8:	08000613          	li	a2,128
    80005cac:	f4040593          	addi	a1,s0,-192
    80005cb0:	4501                	li	a0,0
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	088080e7          	jalr	136(ra) # 80002d3a <argstr>
    80005cba:	87aa                	mv	a5,a0
    return -1;
    80005cbc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cbe:	0c07c263          	bltz	a5,80005d82 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cc2:	10000613          	li	a2,256
    80005cc6:	4581                	li	a1,0
    80005cc8:	e4040513          	addi	a0,s0,-448
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	006080e7          	jalr	6(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cd4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cd8:	89a6                	mv	s3,s1
    80005cda:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cdc:	02000a13          	li	s4,32
    80005ce0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ce4:	00391793          	slli	a5,s2,0x3
    80005ce8:	e3040593          	addi	a1,s0,-464
    80005cec:	e3843503          	ld	a0,-456(s0)
    80005cf0:	953e                	add	a0,a0,a5
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	f6a080e7          	jalr	-150(ra) # 80002c5c <fetchaddr>
    80005cfa:	02054a63          	bltz	a0,80005d2e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005cfe:	e3043783          	ld	a5,-464(s0)
    80005d02:	c3b9                	beqz	a5,80005d48 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	de2080e7          	jalr	-542(ra) # 80000ae6 <kalloc>
    80005d0c:	85aa                	mv	a1,a0
    80005d0e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d12:	cd11                	beqz	a0,80005d2e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d14:	6605                	lui	a2,0x1
    80005d16:	e3043503          	ld	a0,-464(s0)
    80005d1a:	ffffd097          	auipc	ra,0xffffd
    80005d1e:	f94080e7          	jalr	-108(ra) # 80002cae <fetchstr>
    80005d22:	00054663          	bltz	a0,80005d2e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d26:	0905                	addi	s2,s2,1
    80005d28:	09a1                	addi	s3,s3,8
    80005d2a:	fb491be3          	bne	s2,s4,80005ce0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d2e:	10048913          	addi	s2,s1,256
    80005d32:	6088                	ld	a0,0(s1)
    80005d34:	c531                	beqz	a0,80005d80 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d36:	ffffb097          	auipc	ra,0xffffb
    80005d3a:	cb4080e7          	jalr	-844(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d3e:	04a1                	addi	s1,s1,8
    80005d40:	ff2499e3          	bne	s1,s2,80005d32 <sys_exec+0xaa>
  return -1;
    80005d44:	557d                	li	a0,-1
    80005d46:	a835                	j	80005d82 <sys_exec+0xfa>
      argv[i] = 0;
    80005d48:	0a8e                	slli	s5,s5,0x3
    80005d4a:	fc040793          	addi	a5,s0,-64
    80005d4e:	9abe                	add	s5,s5,a5
    80005d50:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d54:	e4040593          	addi	a1,s0,-448
    80005d58:	f4040513          	addi	a0,s0,-192
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	172080e7          	jalr	370(ra) # 80004ece <exec>
    80005d64:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d66:	10048993          	addi	s3,s1,256
    80005d6a:	6088                	ld	a0,0(s1)
    80005d6c:	c901                	beqz	a0,80005d7c <sys_exec+0xf4>
    kfree(argv[i]);
    80005d6e:	ffffb097          	auipc	ra,0xffffb
    80005d72:	c7c080e7          	jalr	-900(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d76:	04a1                	addi	s1,s1,8
    80005d78:	ff3499e3          	bne	s1,s3,80005d6a <sys_exec+0xe2>
  return ret;
    80005d7c:	854a                	mv	a0,s2
    80005d7e:	a011                	j	80005d82 <sys_exec+0xfa>
  return -1;
    80005d80:	557d                	li	a0,-1
}
    80005d82:	60be                	ld	ra,456(sp)
    80005d84:	641e                	ld	s0,448(sp)
    80005d86:	74fa                	ld	s1,440(sp)
    80005d88:	795a                	ld	s2,432(sp)
    80005d8a:	79ba                	ld	s3,424(sp)
    80005d8c:	7a1a                	ld	s4,416(sp)
    80005d8e:	6afa                	ld	s5,408(sp)
    80005d90:	6179                	addi	sp,sp,464
    80005d92:	8082                	ret

0000000080005d94 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d94:	7139                	addi	sp,sp,-64
    80005d96:	fc06                	sd	ra,56(sp)
    80005d98:	f822                	sd	s0,48(sp)
    80005d9a:	f426                	sd	s1,40(sp)
    80005d9c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d9e:	ffffc097          	auipc	ra,0xffffc
    80005da2:	c0e080e7          	jalr	-1010(ra) # 800019ac <myproc>
    80005da6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005da8:	fd840593          	addi	a1,s0,-40
    80005dac:	4501                	li	a0,0
    80005dae:	ffffd097          	auipc	ra,0xffffd
    80005db2:	f6c080e7          	jalr	-148(ra) # 80002d1a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005db6:	fc840593          	addi	a1,s0,-56
    80005dba:	fd040513          	addi	a0,s0,-48
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	dc6080e7          	jalr	-570(ra) # 80004b84 <pipealloc>
    return -1;
    80005dc6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dc8:	0c054463          	bltz	a0,80005e90 <sys_pipe+0xfc>
  fd0 = -1;
    80005dcc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dd0:	fd043503          	ld	a0,-48(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	51a080e7          	jalr	1306(ra) # 800052ee <fdalloc>
    80005ddc:	fca42223          	sw	a0,-60(s0)
    80005de0:	08054b63          	bltz	a0,80005e76 <sys_pipe+0xe2>
    80005de4:	fc843503          	ld	a0,-56(s0)
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	506080e7          	jalr	1286(ra) # 800052ee <fdalloc>
    80005df0:	fca42023          	sw	a0,-64(s0)
    80005df4:	06054863          	bltz	a0,80005e64 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df8:	4691                	li	a3,4
    80005dfa:	fc440613          	addi	a2,s0,-60
    80005dfe:	fd843583          	ld	a1,-40(s0)
    80005e02:	6ca8                	ld	a0,88(s1)
    80005e04:	ffffc097          	auipc	ra,0xffffc
    80005e08:	864080e7          	jalr	-1948(ra) # 80001668 <copyout>
    80005e0c:	02054063          	bltz	a0,80005e2c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e10:	4691                	li	a3,4
    80005e12:	fc040613          	addi	a2,s0,-64
    80005e16:	fd843583          	ld	a1,-40(s0)
    80005e1a:	0591                	addi	a1,a1,4
    80005e1c:	6ca8                	ld	a0,88(s1)
    80005e1e:	ffffc097          	auipc	ra,0xffffc
    80005e22:	84a080e7          	jalr	-1974(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e26:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e28:	06055463          	bgez	a0,80005e90 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e2c:	fc442783          	lw	a5,-60(s0)
    80005e30:	07f9                	addi	a5,a5,30
    80005e32:	078e                	slli	a5,a5,0x3
    80005e34:	97a6                	add	a5,a5,s1
    80005e36:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e3a:	fc042503          	lw	a0,-64(s0)
    80005e3e:	0579                	addi	a0,a0,30
    80005e40:	050e                	slli	a0,a0,0x3
    80005e42:	94aa                	add	s1,s1,a0
    80005e44:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e48:	fd043503          	ld	a0,-48(s0)
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	a08080e7          	jalr	-1528(ra) # 80004854 <fileclose>
    fileclose(wf);
    80005e54:	fc843503          	ld	a0,-56(s0)
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	9fc080e7          	jalr	-1540(ra) # 80004854 <fileclose>
    return -1;
    80005e60:	57fd                	li	a5,-1
    80005e62:	a03d                	j	80005e90 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e64:	fc442783          	lw	a5,-60(s0)
    80005e68:	0007c763          	bltz	a5,80005e76 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e6c:	07f9                	addi	a5,a5,30
    80005e6e:	078e                	slli	a5,a5,0x3
    80005e70:	94be                	add	s1,s1,a5
    80005e72:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e76:	fd043503          	ld	a0,-48(s0)
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	9da080e7          	jalr	-1574(ra) # 80004854 <fileclose>
    fileclose(wf);
    80005e82:	fc843503          	ld	a0,-56(s0)
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	9ce080e7          	jalr	-1586(ra) # 80004854 <fileclose>
    return -1;
    80005e8e:	57fd                	li	a5,-1
}
    80005e90:	853e                	mv	a0,a5
    80005e92:	70e2                	ld	ra,56(sp)
    80005e94:	7442                	ld	s0,48(sp)
    80005e96:	74a2                	ld	s1,40(sp)
    80005e98:	6121                	addi	sp,sp,64
    80005e9a:	8082                	ret
    80005e9c:	0000                	unimp
	...

0000000080005ea0 <kernelvec>:
    80005ea0:	7111                	addi	sp,sp,-256
    80005ea2:	e006                	sd	ra,0(sp)
    80005ea4:	e40a                	sd	sp,8(sp)
    80005ea6:	e80e                	sd	gp,16(sp)
    80005ea8:	ec12                	sd	tp,24(sp)
    80005eaa:	f016                	sd	t0,32(sp)
    80005eac:	f41a                	sd	t1,40(sp)
    80005eae:	f81e                	sd	t2,48(sp)
    80005eb0:	fc22                	sd	s0,56(sp)
    80005eb2:	e0a6                	sd	s1,64(sp)
    80005eb4:	e4aa                	sd	a0,72(sp)
    80005eb6:	e8ae                	sd	a1,80(sp)
    80005eb8:	ecb2                	sd	a2,88(sp)
    80005eba:	f0b6                	sd	a3,96(sp)
    80005ebc:	f4ba                	sd	a4,104(sp)
    80005ebe:	f8be                	sd	a5,112(sp)
    80005ec0:	fcc2                	sd	a6,120(sp)
    80005ec2:	e146                	sd	a7,128(sp)
    80005ec4:	e54a                	sd	s2,136(sp)
    80005ec6:	e94e                	sd	s3,144(sp)
    80005ec8:	ed52                	sd	s4,152(sp)
    80005eca:	f156                	sd	s5,160(sp)
    80005ecc:	f55a                	sd	s6,168(sp)
    80005ece:	f95e                	sd	s7,176(sp)
    80005ed0:	fd62                	sd	s8,184(sp)
    80005ed2:	e1e6                	sd	s9,192(sp)
    80005ed4:	e5ea                	sd	s10,200(sp)
    80005ed6:	e9ee                	sd	s11,208(sp)
    80005ed8:	edf2                	sd	t3,216(sp)
    80005eda:	f1f6                	sd	t4,224(sp)
    80005edc:	f5fa                	sd	t5,232(sp)
    80005ede:	f9fe                	sd	t6,240(sp)
    80005ee0:	c49fc0ef          	jal	ra,80002b28 <kerneltrap>
    80005ee4:	6082                	ld	ra,0(sp)
    80005ee6:	6122                	ld	sp,8(sp)
    80005ee8:	61c2                	ld	gp,16(sp)
    80005eea:	7282                	ld	t0,32(sp)
    80005eec:	7322                	ld	t1,40(sp)
    80005eee:	73c2                	ld	t2,48(sp)
    80005ef0:	7462                	ld	s0,56(sp)
    80005ef2:	6486                	ld	s1,64(sp)
    80005ef4:	6526                	ld	a0,72(sp)
    80005ef6:	65c6                	ld	a1,80(sp)
    80005ef8:	6666                	ld	a2,88(sp)
    80005efa:	7686                	ld	a3,96(sp)
    80005efc:	7726                	ld	a4,104(sp)
    80005efe:	77c6                	ld	a5,112(sp)
    80005f00:	7866                	ld	a6,120(sp)
    80005f02:	688a                	ld	a7,128(sp)
    80005f04:	692a                	ld	s2,136(sp)
    80005f06:	69ca                	ld	s3,144(sp)
    80005f08:	6a6a                	ld	s4,152(sp)
    80005f0a:	7a8a                	ld	s5,160(sp)
    80005f0c:	7b2a                	ld	s6,168(sp)
    80005f0e:	7bca                	ld	s7,176(sp)
    80005f10:	7c6a                	ld	s8,184(sp)
    80005f12:	6c8e                	ld	s9,192(sp)
    80005f14:	6d2e                	ld	s10,200(sp)
    80005f16:	6dce                	ld	s11,208(sp)
    80005f18:	6e6e                	ld	t3,216(sp)
    80005f1a:	7e8e                	ld	t4,224(sp)
    80005f1c:	7f2e                	ld	t5,232(sp)
    80005f1e:	7fce                	ld	t6,240(sp)
    80005f20:	6111                	addi	sp,sp,256
    80005f22:	10200073          	sret
    80005f26:	00000013          	nop
    80005f2a:	00000013          	nop
    80005f2e:	0001                	nop

0000000080005f30 <timervec>:
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	e10c                	sd	a1,0(a0)
    80005f36:	e510                	sd	a2,8(a0)
    80005f38:	e914                	sd	a3,16(a0)
    80005f3a:	6d0c                	ld	a1,24(a0)
    80005f3c:	7110                	ld	a2,32(a0)
    80005f3e:	6194                	ld	a3,0(a1)
    80005f40:	96b2                	add	a3,a3,a2
    80005f42:	e194                	sd	a3,0(a1)
    80005f44:	4589                	li	a1,2
    80005f46:	14459073          	csrw	sip,a1
    80005f4a:	6914                	ld	a3,16(a0)
    80005f4c:	6510                	ld	a2,8(a0)
    80005f4e:	610c                	ld	a1,0(a0)
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	30200073          	mret
	...

0000000080005f5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f5a:	1141                	addi	sp,sp,-16
    80005f5c:	e422                	sd	s0,8(sp)
    80005f5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f60:	0c0007b7          	lui	a5,0xc000
    80005f64:	4705                	li	a4,1
    80005f66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f68:	c3d8                	sw	a4,4(a5)
}
    80005f6a:	6422                	ld	s0,8(sp)
    80005f6c:	0141                	addi	sp,sp,16
    80005f6e:	8082                	ret

0000000080005f70 <plicinithart>:

void
plicinithart(void)
{
    80005f70:	1141                	addi	sp,sp,-16
    80005f72:	e406                	sd	ra,8(sp)
    80005f74:	e022                	sd	s0,0(sp)
    80005f76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a08080e7          	jalr	-1528(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f80:	0085171b          	slliw	a4,a0,0x8
    80005f84:	0c0027b7          	lui	a5,0xc002
    80005f88:	97ba                	add	a5,a5,a4
    80005f8a:	40200713          	li	a4,1026
    80005f8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f92:	00d5151b          	slliw	a0,a0,0xd
    80005f96:	0c2017b7          	lui	a5,0xc201
    80005f9a:	953e                	add	a0,a0,a5
    80005f9c:	00052023          	sw	zero,0(a0)
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret

0000000080005fa8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fa8:	1141                	addi	sp,sp,-16
    80005faa:	e406                	sd	ra,8(sp)
    80005fac:	e022                	sd	s0,0(sp)
    80005fae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb0:	ffffc097          	auipc	ra,0xffffc
    80005fb4:	9d0080e7          	jalr	-1584(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fb8:	00d5179b          	slliw	a5,a0,0xd
    80005fbc:	0c201537          	lui	a0,0xc201
    80005fc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fc2:	4148                	lw	a0,4(a0)
    80005fc4:	60a2                	ld	ra,8(sp)
    80005fc6:	6402                	ld	s0,0(sp)
    80005fc8:	0141                	addi	sp,sp,16
    80005fca:	8082                	ret

0000000080005fcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fcc:	1101                	addi	sp,sp,-32
    80005fce:	ec06                	sd	ra,24(sp)
    80005fd0:	e822                	sd	s0,16(sp)
    80005fd2:	e426                	sd	s1,8(sp)
    80005fd4:	1000                	addi	s0,sp,32
    80005fd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	9a8080e7          	jalr	-1624(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fe0:	00d5151b          	slliw	a0,a0,0xd
    80005fe4:	0c2017b7          	lui	a5,0xc201
    80005fe8:	97aa                	add	a5,a5,a0
    80005fea:	c3c4                	sw	s1,4(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6105                	addi	sp,sp,32
    80005ff4:	8082                	ret

0000000080005ff6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ff6:	1141                	addi	sp,sp,-16
    80005ff8:	e406                	sd	ra,8(sp)
    80005ffa:	e022                	sd	s0,0(sp)
    80005ffc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ffe:	479d                	li	a5,7
    80006000:	04a7cc63          	blt	a5,a0,80006058 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006004:	0001d797          	auipc	a5,0x1d
    80006008:	81c78793          	addi	a5,a5,-2020 # 80022820 <disk>
    8000600c:	97aa                	add	a5,a5,a0
    8000600e:	0187c783          	lbu	a5,24(a5)
    80006012:	ebb9                	bnez	a5,80006068 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006014:	00451613          	slli	a2,a0,0x4
    80006018:	0001d797          	auipc	a5,0x1d
    8000601c:	80878793          	addi	a5,a5,-2040 # 80022820 <disk>
    80006020:	6394                	ld	a3,0(a5)
    80006022:	96b2                	add	a3,a3,a2
    80006024:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006028:	6398                	ld	a4,0(a5)
    8000602a:	9732                	add	a4,a4,a2
    8000602c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006030:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006034:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006038:	953e                	add	a0,a0,a5
    8000603a:	4785                	li	a5,1
    8000603c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006040:	0001c517          	auipc	a0,0x1c
    80006044:	7f850513          	addi	a0,a0,2040 # 80022838 <disk+0x18>
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	098080e7          	jalr	152(ra) # 800020e0 <wakeup>
}
    80006050:	60a2                	ld	ra,8(sp)
    80006052:	6402                	ld	s0,0(sp)
    80006054:	0141                	addi	sp,sp,16
    80006056:	8082                	ret
    panic("free_desc 1");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	70850513          	addi	a0,a0,1800 # 80008760 <syscalls+0x310>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006068:	00002517          	auipc	a0,0x2
    8000606c:	70850513          	addi	a0,a0,1800 # 80008770 <syscalls+0x320>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>

0000000080006078 <virtio_disk_init>:
{
    80006078:	1101                	addi	sp,sp,-32
    8000607a:	ec06                	sd	ra,24(sp)
    8000607c:	e822                	sd	s0,16(sp)
    8000607e:	e426                	sd	s1,8(sp)
    80006080:	e04a                	sd	s2,0(sp)
    80006082:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006084:	00002597          	auipc	a1,0x2
    80006088:	6fc58593          	addi	a1,a1,1788 # 80008780 <syscalls+0x330>
    8000608c:	0001d517          	auipc	a0,0x1d
    80006090:	8bc50513          	addi	a0,a0,-1860 # 80022948 <disk+0x128>
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	ab2080e7          	jalr	-1358(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	4398                	lw	a4,0(a5)
    800060a2:	2701                	sext.w	a4,a4
    800060a4:	747277b7          	lui	a5,0x74727
    800060a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ac:	14f71c63          	bne	a4,a5,80006204 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060b0:	100017b7          	lui	a5,0x10001
    800060b4:	43dc                	lw	a5,4(a5)
    800060b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b8:	4709                	li	a4,2
    800060ba:	14e79563          	bne	a5,a4,80006204 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060be:	100017b7          	lui	a5,0x10001
    800060c2:	479c                	lw	a5,8(a5)
    800060c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060c6:	12e79f63          	bne	a5,a4,80006204 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ca:	100017b7          	lui	a5,0x10001
    800060ce:	47d8                	lw	a4,12(a5)
    800060d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060d2:	554d47b7          	lui	a5,0x554d4
    800060d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060da:	12f71563          	bne	a4,a5,80006204 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e6:	4705                	li	a4,1
    800060e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ea:	470d                	li	a4,3
    800060ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060f0:	c7ffe737          	lui	a4,0xc7ffe
    800060f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbdff>
    800060f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060fa:	2701                	sext.w	a4,a4
    800060fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fe:	472d                	li	a4,11
    80006100:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006102:	5bbc                	lw	a5,112(a5)
    80006104:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006108:	8ba1                	andi	a5,a5,8
    8000610a:	10078563          	beqz	a5,80006214 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006116:	43fc                	lw	a5,68(a5)
    80006118:	2781                	sext.w	a5,a5
    8000611a:	10079563          	bnez	a5,80006224 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	5bdc                	lw	a5,52(a5)
    80006124:	2781                	sext.w	a5,a5
  if(max == 0)
    80006126:	10078763          	beqz	a5,80006234 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000612a:	471d                	li	a4,7
    8000612c:	10f77c63          	bgeu	a4,a5,80006244 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	9b6080e7          	jalr	-1610(ra) # 80000ae6 <kalloc>
    80006138:	0001c497          	auipc	s1,0x1c
    8000613c:	6e848493          	addi	s1,s1,1768 # 80022820 <disk>
    80006140:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	9a4080e7          	jalr	-1628(ra) # 80000ae6 <kalloc>
    8000614a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	99a080e7          	jalr	-1638(ra) # 80000ae6 <kalloc>
    80006154:	87aa                	mv	a5,a0
    80006156:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006158:	6088                	ld	a0,0(s1)
    8000615a:	cd6d                	beqz	a0,80006254 <virtio_disk_init+0x1dc>
    8000615c:	0001c717          	auipc	a4,0x1c
    80006160:	6cc73703          	ld	a4,1740(a4) # 80022828 <disk+0x8>
    80006164:	cb65                	beqz	a4,80006254 <virtio_disk_init+0x1dc>
    80006166:	c7fd                	beqz	a5,80006254 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006168:	6605                	lui	a2,0x1
    8000616a:	4581                	li	a1,0
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	b66080e7          	jalr	-1178(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006174:	0001c497          	auipc	s1,0x1c
    80006178:	6ac48493          	addi	s1,s1,1708 # 80022820 <disk>
    8000617c:	6605                	lui	a2,0x1
    8000617e:	4581                	li	a1,0
    80006180:	6488                	ld	a0,8(s1)
    80006182:	ffffb097          	auipc	ra,0xffffb
    80006186:	b50080e7          	jalr	-1200(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000618a:	6605                	lui	a2,0x1
    8000618c:	4581                	li	a1,0
    8000618e:	6888                	ld	a0,16(s1)
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	b42080e7          	jalr	-1214(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006198:	100017b7          	lui	a5,0x10001
    8000619c:	4721                	li	a4,8
    8000619e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061a0:	4098                	lw	a4,0(s1)
    800061a2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061a6:	40d8                	lw	a4,4(s1)
    800061a8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ac:	6498                	ld	a4,8(s1)
    800061ae:	0007069b          	sext.w	a3,a4
    800061b2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061b6:	9701                	srai	a4,a4,0x20
    800061b8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061bc:	6898                	ld	a4,16(s1)
    800061be:	0007069b          	sext.w	a3,a4
    800061c2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061c6:	9701                	srai	a4,a4,0x20
    800061c8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061cc:	4705                	li	a4,1
    800061ce:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061d0:	00e48c23          	sb	a4,24(s1)
    800061d4:	00e48ca3          	sb	a4,25(s1)
    800061d8:	00e48d23          	sb	a4,26(s1)
    800061dc:	00e48da3          	sb	a4,27(s1)
    800061e0:	00e48e23          	sb	a4,28(s1)
    800061e4:	00e48ea3          	sb	a4,29(s1)
    800061e8:	00e48f23          	sb	a4,30(s1)
    800061ec:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061f0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f4:	0727a823          	sw	s2,112(a5)
}
    800061f8:	60e2                	ld	ra,24(sp)
    800061fa:	6442                	ld	s0,16(sp)
    800061fc:	64a2                	ld	s1,8(sp)
    800061fe:	6902                	ld	s2,0(sp)
    80006200:	6105                	addi	sp,sp,32
    80006202:	8082                	ret
    panic("could not find virtio disk");
    80006204:	00002517          	auipc	a0,0x2
    80006208:	58c50513          	addi	a0,a0,1420 # 80008790 <syscalls+0x340>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	332080e7          	jalr	818(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006214:	00002517          	auipc	a0,0x2
    80006218:	59c50513          	addi	a0,a0,1436 # 800087b0 <syscalls+0x360>
    8000621c:	ffffa097          	auipc	ra,0xffffa
    80006220:	322080e7          	jalr	802(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006224:	00002517          	auipc	a0,0x2
    80006228:	5ac50513          	addi	a0,a0,1452 # 800087d0 <syscalls+0x380>
    8000622c:	ffffa097          	auipc	ra,0xffffa
    80006230:	312080e7          	jalr	786(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006234:	00002517          	auipc	a0,0x2
    80006238:	5bc50513          	addi	a0,a0,1468 # 800087f0 <syscalls+0x3a0>
    8000623c:	ffffa097          	auipc	ra,0xffffa
    80006240:	302080e7          	jalr	770(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006244:	00002517          	auipc	a0,0x2
    80006248:	5cc50513          	addi	a0,a0,1484 # 80008810 <syscalls+0x3c0>
    8000624c:	ffffa097          	auipc	ra,0xffffa
    80006250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006254:	00002517          	auipc	a0,0x2
    80006258:	5dc50513          	addi	a0,a0,1500 # 80008830 <syscalls+0x3e0>
    8000625c:	ffffa097          	auipc	ra,0xffffa
    80006260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>

0000000080006264 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006264:	7119                	addi	sp,sp,-128
    80006266:	fc86                	sd	ra,120(sp)
    80006268:	f8a2                	sd	s0,112(sp)
    8000626a:	f4a6                	sd	s1,104(sp)
    8000626c:	f0ca                	sd	s2,96(sp)
    8000626e:	ecce                	sd	s3,88(sp)
    80006270:	e8d2                	sd	s4,80(sp)
    80006272:	e4d6                	sd	s5,72(sp)
    80006274:	e0da                	sd	s6,64(sp)
    80006276:	fc5e                	sd	s7,56(sp)
    80006278:	f862                	sd	s8,48(sp)
    8000627a:	f466                	sd	s9,40(sp)
    8000627c:	f06a                	sd	s10,32(sp)
    8000627e:	ec6e                	sd	s11,24(sp)
    80006280:	0100                	addi	s0,sp,128
    80006282:	8aaa                	mv	s5,a0
    80006284:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006286:	00c52d03          	lw	s10,12(a0)
    8000628a:	001d1d1b          	slliw	s10,s10,0x1
    8000628e:	1d02                	slli	s10,s10,0x20
    80006290:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006294:	0001c517          	auipc	a0,0x1c
    80006298:	6b450513          	addi	a0,a0,1716 # 80022948 <disk+0x128>
    8000629c:	ffffb097          	auipc	ra,0xffffb
    800062a0:	93a080e7          	jalr	-1734(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062a6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062a8:	0001cb97          	auipc	s7,0x1c
    800062ac:	578b8b93          	addi	s7,s7,1400 # 80022820 <disk>
  for(int i = 0; i < 3; i++){
    800062b0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062b2:	0001cc97          	auipc	s9,0x1c
    800062b6:	696c8c93          	addi	s9,s9,1686 # 80022948 <disk+0x128>
    800062ba:	a08d                	j	8000631c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062bc:	00fb8733          	add	a4,s7,a5
    800062c0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062c4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062c6:	0207c563          	bltz	a5,800062f0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062ca:	2905                	addiw	s2,s2,1
    800062cc:	0611                	addi	a2,a2,4
    800062ce:	05690c63          	beq	s2,s6,80006326 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800062d2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062d4:	0001c717          	auipc	a4,0x1c
    800062d8:	54c70713          	addi	a4,a4,1356 # 80022820 <disk>
    800062dc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062de:	01874683          	lbu	a3,24(a4)
    800062e2:	fee9                	bnez	a3,800062bc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062e4:	2785                	addiw	a5,a5,1
    800062e6:	0705                	addi	a4,a4,1
    800062e8:	fe979be3          	bne	a5,s1,800062de <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062ec:	57fd                	li	a5,-1
    800062ee:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062f0:	01205d63          	blez	s2,8000630a <virtio_disk_rw+0xa6>
    800062f4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062f6:	000a2503          	lw	a0,0(s4)
    800062fa:	00000097          	auipc	ra,0x0
    800062fe:	cfc080e7          	jalr	-772(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006302:	2d85                	addiw	s11,s11,1
    80006304:	0a11                	addi	s4,s4,4
    80006306:	ffb918e3          	bne	s2,s11,800062f6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000630a:	85e6                	mv	a1,s9
    8000630c:	0001c517          	auipc	a0,0x1c
    80006310:	52c50513          	addi	a0,a0,1324 # 80022838 <disk+0x18>
    80006314:	ffffc097          	auipc	ra,0xffffc
    80006318:	d68080e7          	jalr	-664(ra) # 8000207c <sleep>
  for(int i = 0; i < 3; i++){
    8000631c:	f8040a13          	addi	s4,s0,-128
{
    80006320:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006322:	894e                	mv	s2,s3
    80006324:	b77d                	j	800062d2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006326:	f8042583          	lw	a1,-128(s0)
    8000632a:	00a58793          	addi	a5,a1,10
    8000632e:	0792                	slli	a5,a5,0x4

  if(write)
    80006330:	0001c617          	auipc	a2,0x1c
    80006334:	4f060613          	addi	a2,a2,1264 # 80022820 <disk>
    80006338:	00f60733          	add	a4,a2,a5
    8000633c:	018036b3          	snez	a3,s8
    80006340:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006342:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006346:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000634a:	f6078693          	addi	a3,a5,-160
    8000634e:	6218                	ld	a4,0(a2)
    80006350:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006352:	00878513          	addi	a0,a5,8
    80006356:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006358:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000635a:	6208                	ld	a0,0(a2)
    8000635c:	96aa                	add	a3,a3,a0
    8000635e:	4741                	li	a4,16
    80006360:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006362:	4705                	li	a4,1
    80006364:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006368:	f8442703          	lw	a4,-124(s0)
    8000636c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006370:	0712                	slli	a4,a4,0x4
    80006372:	953a                	add	a0,a0,a4
    80006374:	058a8693          	addi	a3,s5,88
    80006378:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000637a:	6208                	ld	a0,0(a2)
    8000637c:	972a                	add	a4,a4,a0
    8000637e:	40000693          	li	a3,1024
    80006382:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006384:	001c3c13          	seqz	s8,s8
    80006388:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000638a:	001c6c13          	ori	s8,s8,1
    8000638e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006392:	f8842603          	lw	a2,-120(s0)
    80006396:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000639a:	0001c697          	auipc	a3,0x1c
    8000639e:	48668693          	addi	a3,a3,1158 # 80022820 <disk>
    800063a2:	00258713          	addi	a4,a1,2
    800063a6:	0712                	slli	a4,a4,0x4
    800063a8:	9736                	add	a4,a4,a3
    800063aa:	587d                	li	a6,-1
    800063ac:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063b0:	0612                	slli	a2,a2,0x4
    800063b2:	9532                	add	a0,a0,a2
    800063b4:	f9078793          	addi	a5,a5,-112
    800063b8:	97b6                	add	a5,a5,a3
    800063ba:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800063bc:	629c                	ld	a5,0(a3)
    800063be:	97b2                	add	a5,a5,a2
    800063c0:	4605                	li	a2,1
    800063c2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063c4:	4509                	li	a0,2
    800063c6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800063ca:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063ce:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800063d2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063d6:	6698                	ld	a4,8(a3)
    800063d8:	00275783          	lhu	a5,2(a4)
    800063dc:	8b9d                	andi	a5,a5,7
    800063de:	0786                	slli	a5,a5,0x1
    800063e0:	97ba                	add	a5,a5,a4
    800063e2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800063e6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063ea:	6698                	ld	a4,8(a3)
    800063ec:	00275783          	lhu	a5,2(a4)
    800063f0:	2785                	addiw	a5,a5,1
    800063f2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063f6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063fa:	100017b7          	lui	a5,0x10001
    800063fe:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006402:	004aa783          	lw	a5,4(s5)
    80006406:	02c79163          	bne	a5,a2,80006428 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000640a:	0001c917          	auipc	s2,0x1c
    8000640e:	53e90913          	addi	s2,s2,1342 # 80022948 <disk+0x128>
  while(b->disk == 1) {
    80006412:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006414:	85ca                	mv	a1,s2
    80006416:	8556                	mv	a0,s5
    80006418:	ffffc097          	auipc	ra,0xffffc
    8000641c:	c64080e7          	jalr	-924(ra) # 8000207c <sleep>
  while(b->disk == 1) {
    80006420:	004aa783          	lw	a5,4(s5)
    80006424:	fe9788e3          	beq	a5,s1,80006414 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006428:	f8042903          	lw	s2,-128(s0)
    8000642c:	00290793          	addi	a5,s2,2
    80006430:	00479713          	slli	a4,a5,0x4
    80006434:	0001c797          	auipc	a5,0x1c
    80006438:	3ec78793          	addi	a5,a5,1004 # 80022820 <disk>
    8000643c:	97ba                	add	a5,a5,a4
    8000643e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006442:	0001c997          	auipc	s3,0x1c
    80006446:	3de98993          	addi	s3,s3,990 # 80022820 <disk>
    8000644a:	00491713          	slli	a4,s2,0x4
    8000644e:	0009b783          	ld	a5,0(s3)
    80006452:	97ba                	add	a5,a5,a4
    80006454:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006458:	854a                	mv	a0,s2
    8000645a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000645e:	00000097          	auipc	ra,0x0
    80006462:	b98080e7          	jalr	-1128(ra) # 80005ff6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006466:	8885                	andi	s1,s1,1
    80006468:	f0ed                	bnez	s1,8000644a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000646a:	0001c517          	auipc	a0,0x1c
    8000646e:	4de50513          	addi	a0,a0,1246 # 80022948 <disk+0x128>
    80006472:	ffffb097          	auipc	ra,0xffffb
    80006476:	818080e7          	jalr	-2024(ra) # 80000c8a <release>
}
    8000647a:	70e6                	ld	ra,120(sp)
    8000647c:	7446                	ld	s0,112(sp)
    8000647e:	74a6                	ld	s1,104(sp)
    80006480:	7906                	ld	s2,96(sp)
    80006482:	69e6                	ld	s3,88(sp)
    80006484:	6a46                	ld	s4,80(sp)
    80006486:	6aa6                	ld	s5,72(sp)
    80006488:	6b06                	ld	s6,64(sp)
    8000648a:	7be2                	ld	s7,56(sp)
    8000648c:	7c42                	ld	s8,48(sp)
    8000648e:	7ca2                	ld	s9,40(sp)
    80006490:	7d02                	ld	s10,32(sp)
    80006492:	6de2                	ld	s11,24(sp)
    80006494:	6109                	addi	sp,sp,128
    80006496:	8082                	ret

0000000080006498 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006498:	1101                	addi	sp,sp,-32
    8000649a:	ec06                	sd	ra,24(sp)
    8000649c:	e822                	sd	s0,16(sp)
    8000649e:	e426                	sd	s1,8(sp)
    800064a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064a2:	0001c497          	auipc	s1,0x1c
    800064a6:	37e48493          	addi	s1,s1,894 # 80022820 <disk>
    800064aa:	0001c517          	auipc	a0,0x1c
    800064ae:	49e50513          	addi	a0,a0,1182 # 80022948 <disk+0x128>
    800064b2:	ffffa097          	auipc	ra,0xffffa
    800064b6:	724080e7          	jalr	1828(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064ba:	10001737          	lui	a4,0x10001
    800064be:	533c                	lw	a5,96(a4)
    800064c0:	8b8d                	andi	a5,a5,3
    800064c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064c8:	689c                	ld	a5,16(s1)
    800064ca:	0204d703          	lhu	a4,32(s1)
    800064ce:	0027d783          	lhu	a5,2(a5)
    800064d2:	04f70863          	beq	a4,a5,80006522 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064d6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064da:	6898                	ld	a4,16(s1)
    800064dc:	0204d783          	lhu	a5,32(s1)
    800064e0:	8b9d                	andi	a5,a5,7
    800064e2:	078e                	slli	a5,a5,0x3
    800064e4:	97ba                	add	a5,a5,a4
    800064e6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064e8:	00278713          	addi	a4,a5,2
    800064ec:	0712                	slli	a4,a4,0x4
    800064ee:	9726                	add	a4,a4,s1
    800064f0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064f4:	e721                	bnez	a4,8000653c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064f6:	0789                	addi	a5,a5,2
    800064f8:	0792                	slli	a5,a5,0x4
    800064fa:	97a6                	add	a5,a5,s1
    800064fc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064fe:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006502:	ffffc097          	auipc	ra,0xffffc
    80006506:	bde080e7          	jalr	-1058(ra) # 800020e0 <wakeup>

    disk.used_idx += 1;
    8000650a:	0204d783          	lhu	a5,32(s1)
    8000650e:	2785                	addiw	a5,a5,1
    80006510:	17c2                	slli	a5,a5,0x30
    80006512:	93c1                	srli	a5,a5,0x30
    80006514:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006518:	6898                	ld	a4,16(s1)
    8000651a:	00275703          	lhu	a4,2(a4)
    8000651e:	faf71ce3          	bne	a4,a5,800064d6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006522:	0001c517          	auipc	a0,0x1c
    80006526:	42650513          	addi	a0,a0,1062 # 80022948 <disk+0x128>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	760080e7          	jalr	1888(ra) # 80000c8a <release>
}
    80006532:	60e2                	ld	ra,24(sp)
    80006534:	6442                	ld	s0,16(sp)
    80006536:	64a2                	ld	s1,8(sp)
    80006538:	6105                	addi	sp,sp,32
    8000653a:	8082                	ret
      panic("virtio_disk_intr status");
    8000653c:	00002517          	auipc	a0,0x2
    80006540:	30c50513          	addi	a0,a0,780 # 80008848 <syscalls+0x3f8>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	ffa080e7          	jalr	-6(ra) # 8000053e <panic>
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
