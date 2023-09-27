
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
    80000068:	efc78793          	addi	a5,a5,-260 # 80005f60 <timervec>
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
    80000eca:	0da080e7          	jalr	218(ra) # 80005fa0 <plicinithart>
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
    80000f4a:	044080e7          	jalr	68(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	052080e7          	jalr	82(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1fc080e7          	jalr	508(ra) # 80003152 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8a0080e7          	jalr	-1888(ra) # 800037fe <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	83e080e7          	jalr	-1986(ra) # 800047a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	13a080e7          	jalr	314(ra) # 800060a8 <virtio_disk_init>
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
    80001a24:	d5e080e7          	jalr	-674(ra) # 8000377e <fsinit>
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
    80001d0e:	496080e7          	jalr	1174(ra) # 800041a0 <namei>
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
    80001e3e:	9fc080e7          	jalr	-1540(ra) # 80004836 <filedup>
    80001e42:	00a93023          	sd	a0,0(s2)
    80001e46:	b7e5                	j	80001e2e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e48:	170ab503          	ld	a0,368(s5)
    80001e4c:	00002097          	auipc	ra,0x2
    80001e50:	b70080e7          	jalr	-1168(ra) # 800039bc <idup>
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
    800021f4:	698080e7          	jalr	1688(ra) # 80004888 <fileclose>
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
    8000220c:	1b4080e7          	jalr	436(ra) # 800043bc <begin_op>
  iput(p->cwd);
    80002210:	1709b503          	ld	a0,368(s3)
    80002214:	00002097          	auipc	ra,0x2
    80002218:	9a0080e7          	jalr	-1632(ra) # 80003bb4 <iput>
  end_op();
    8000221c:	00002097          	auipc	ra,0x2
    80002220:	220080e7          	jalr	544(ra) # 8000443c <end_op>
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
    80002830:	6a478793          	addi	a5,a5,1700 # 80005ed0 <kernelvec>
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
    8000295e:	67e080e7          	jalr	1662(ra) # 80005fd8 <plic_claim>
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
    8000298c:	674080e7          	jalr	1652(ra) # 80005ffc <plic_complete>
    return 1;
    80002990:	4505                	li	a0,1
    80002992:	bf55                	j	80002946 <devintr+0x1e>
      uartintr();
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	006080e7          	jalr	6(ra) # 8000099a <uartintr>
    8000299c:	b7ed                	j	80002986 <devintr+0x5e>
      virtio_disk_intr();
    8000299e:	00004097          	auipc	ra,0x4
    800029a2:	b2a080e7          	jalr	-1238(ra) # 800064c8 <virtio_disk_intr>
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
    800029e4:	4f078793          	addi	a5,a5,1264 # 80005ed0 <kernelvec>
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
    80002a66:	3a2080e7          	jalr	930(ra) # 80002e04 <syscall>
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

0000000080002c5c <sys_sigreturn>:
  myproc()->ticks = ticks;

  return 0;
}
uint64 sys_sigreturn(void)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	d46080e7          	jalr	-698(ra) # 800019ac <myproc>
    80002c6e:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alram_tf, PGSIZE);
    80002c70:	6605                	lui	a2,0x1
    80002c72:	792c                	ld	a1,112(a0)
    80002c74:	7128                	ld	a0,96(a0)
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	0b8080e7          	jalr	184(ra) # 80000d2e <memmove>

  kfree(p->alram_tf);
    80002c7e:	78a8                	ld	a0,112(s1)
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	d6a080e7          	jalr	-662(ra) # 800009ea <kfree>
  p->alram_tf = 0;
    80002c88:	0604b823          	sd	zero,112(s1)
  p->alarm = 0;
    80002c8c:	0604ac23          	sw	zero,120(s1)
  p->current_ticks = 0;
    80002c90:	0604a623          	sw	zero,108(s1)
  return 0;
    80002c94:	4501                	li	a0,0
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <fetchaddr>:
{
    80002ca0:	1101                	addi	sp,sp,-32
    80002ca2:	ec06                	sd	ra,24(sp)
    80002ca4:	e822                	sd	s0,16(sp)
    80002ca6:	e426                	sd	s1,8(sp)
    80002ca8:	e04a                	sd	s2,0(sp)
    80002caa:	1000                	addi	s0,sp,32
    80002cac:	84aa                	mv	s1,a0
    80002cae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	cfc080e7          	jalr	-772(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002cb8:	653c                	ld	a5,72(a0)
    80002cba:	02f4f863          	bgeu	s1,a5,80002cea <fetchaddr+0x4a>
    80002cbe:	00848713          	addi	a4,s1,8
    80002cc2:	02e7e663          	bltu	a5,a4,80002cee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cc6:	46a1                	li	a3,8
    80002cc8:	8626                	mv	a2,s1
    80002cca:	85ca                	mv	a1,s2
    80002ccc:	6d28                	ld	a0,88(a0)
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	a26080e7          	jalr	-1498(ra) # 800016f4 <copyin>
    80002cd6:	00a03533          	snez	a0,a0
    80002cda:	40a00533          	neg	a0,a0
}
    80002cde:	60e2                	ld	ra,24(sp)
    80002ce0:	6442                	ld	s0,16(sp)
    80002ce2:	64a2                	ld	s1,8(sp)
    80002ce4:	6902                	ld	s2,0(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret
    return -1;
    80002cea:	557d                	li	a0,-1
    80002cec:	bfcd                	j	80002cde <fetchaddr+0x3e>
    80002cee:	557d                	li	a0,-1
    80002cf0:	b7fd                	j	80002cde <fetchaddr+0x3e>

0000000080002cf2 <fetchstr>:
{
    80002cf2:	7179                	addi	sp,sp,-48
    80002cf4:	f406                	sd	ra,40(sp)
    80002cf6:	f022                	sd	s0,32(sp)
    80002cf8:	ec26                	sd	s1,24(sp)
    80002cfa:	e84a                	sd	s2,16(sp)
    80002cfc:	e44e                	sd	s3,8(sp)
    80002cfe:	1800                	addi	s0,sp,48
    80002d00:	892a                	mv	s2,a0
    80002d02:	84ae                	mv	s1,a1
    80002d04:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	ca6080e7          	jalr	-858(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d0e:	86ce                	mv	a3,s3
    80002d10:	864a                	mv	a2,s2
    80002d12:	85a6                	mv	a1,s1
    80002d14:	6d28                	ld	a0,88(a0)
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	a6c080e7          	jalr	-1428(ra) # 80001782 <copyinstr>
    80002d1e:	00054e63          	bltz	a0,80002d3a <fetchstr+0x48>
  return strlen(buf);
    80002d22:	8526                	mv	a0,s1
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	12a080e7          	jalr	298(ra) # 80000e4e <strlen>
}
    80002d2c:	70a2                	ld	ra,40(sp)
    80002d2e:	7402                	ld	s0,32(sp)
    80002d30:	64e2                	ld	s1,24(sp)
    80002d32:	6942                	ld	s2,16(sp)
    80002d34:	69a2                	ld	s3,8(sp)
    80002d36:	6145                	addi	sp,sp,48
    80002d38:	8082                	ret
    return -1;
    80002d3a:	557d                	li	a0,-1
    80002d3c:	bfc5                	j	80002d2c <fetchstr+0x3a>

0000000080002d3e <argint>:
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	eaa080e7          	jalr	-342(ra) # 80002bf4 <argraw>
    80002d52:	c088                	sw	a0,0(s1)
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <argaddr>:
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	1000                	addi	s0,sp,32
    80002d68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d6a:	00000097          	auipc	ra,0x0
    80002d6e:	e8a080e7          	jalr	-374(ra) # 80002bf4 <argraw>
    80002d72:	e088                	sd	a0,0(s1)
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_sigalarm>:
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	1800                	addi	s0,sp,48
    80002d86:	fca42e23          	sw	a0,-36(s0)
  argint(0,&ticks);
    80002d8a:	fdc40593          	addi	a1,s0,-36
    80002d8e:	4501                	li	a0,0
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	fae080e7          	jalr	-82(ra) # 80002d3e <argint>
  argaddr(1,&addr);
    80002d98:	fe840593          	addi	a1,s0,-24
    80002d9c:	4505                	li	a0,1
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	fc0080e7          	jalr	-64(ra) # 80002d5e <argaddr>
  myproc()->handler = addr;
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	c06080e7          	jalr	-1018(ra) # 800019ac <myproc>
    80002dae:	fe843783          	ld	a5,-24(s0)
    80002db2:	e93c                	sd	a5,80(a0)
  myproc()->ticks = ticks;
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	bf8080e7          	jalr	-1032(ra) # 800019ac <myproc>
    80002dbc:	fdc42783          	lw	a5,-36(s0)
    80002dc0:	d53c                	sw	a5,104(a0)
}
    80002dc2:	4501                	li	a0,0
    80002dc4:	70a2                	ld	ra,40(sp)
    80002dc6:	7402                	ld	s0,32(sp)
    80002dc8:	6145                	addi	sp,sp,48
    80002dca:	8082                	ret

0000000080002dcc <argstr>:
{
    80002dcc:	7179                	addi	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	e84a                	sd	s2,16(sp)
    80002dd6:	1800                	addi	s0,sp,48
    80002dd8:	84ae                	mv	s1,a1
    80002dda:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002ddc:	fd840593          	addi	a1,s0,-40
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	f7e080e7          	jalr	-130(ra) # 80002d5e <argaddr>
  return fetchstr(addr, buf, max);
    80002de8:	864a                	mv	a2,s2
    80002dea:	85a6                	mv	a1,s1
    80002dec:	fd843503          	ld	a0,-40(s0)
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	f02080e7          	jalr	-254(ra) # 80002cf2 <fetchstr>
}
    80002df8:	70a2                	ld	ra,40(sp)
    80002dfa:	7402                	ld	s0,32(sp)
    80002dfc:	64e2                	ld	s1,24(sp)
    80002dfe:	6942                	ld	s2,16(sp)
    80002e00:	6145                	addi	sp,sp,48
    80002e02:	8082                	ret

0000000080002e04 <syscall>:
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	e04a                	sd	s2,0(sp)
    80002e0e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	b9c080e7          	jalr	-1124(ra) # 800019ac <myproc>
    80002e18:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002e1a:	06053903          	ld	s2,96(a0)
    80002e1e:	0a893783          	ld	a5,168(s2)
    80002e22:	0007869b          	sext.w	a3,a5
  if(num==SYS_read){
    80002e26:	4715                	li	a4,5
    80002e28:	02e68663          	beq	a3,a4,80002e54 <syscall+0x50>
  if(num==SYS_getreadcount){
    80002e2c:	475d                	li	a4,23
    80002e2e:	04e69663          	bne	a3,a4,80002e7a <syscall+0x76>
    p->readcount=readcountvalue;
    80002e32:	00006717          	auipc	a4,0x6
    80002e36:	ab272703          	lw	a4,-1358(a4) # 800088e4 <readcountvalue>
    80002e3a:	d958                	sw	a4,52(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e3c:	37fd                	addiw	a5,a5,-1
    80002e3e:	4661                	li	a2,24
    80002e40:	00000717          	auipc	a4,0x0
    80002e44:	2f870713          	addi	a4,a4,760 # 80003138 <sys_getreadcount>
    80002e48:	04f66663          	bltu	a2,a5,80002e94 <syscall+0x90>
    p->trapframe->a0 = syscalls[num]();
    80002e4c:	9702                	jalr	a4
    80002e4e:	06a93823          	sd	a0,112(s2)
    80002e52:	a8b9                	j	80002eb0 <syscall+0xac>
    readcountvalue++;
    80002e54:	00006617          	auipc	a2,0x6
    80002e58:	a9060613          	addi	a2,a2,-1392 # 800088e4 <readcountvalue>
    80002e5c:	4218                	lw	a4,0(a2)
    80002e5e:	2705                	addiw	a4,a4,1
    80002e60:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e62:	37fd                	addiw	a5,a5,-1
    80002e64:	4761                	li	a4,24
    80002e66:	02f76763          	bltu	a4,a5,80002e94 <syscall+0x90>
    80002e6a:	068e                	slli	a3,a3,0x3
    80002e6c:	00005797          	auipc	a5,0x5
    80002e70:	5e478793          	addi	a5,a5,1508 # 80008450 <syscalls>
    80002e74:	96be                	add	a3,a3,a5
    80002e76:	6298                	ld	a4,0(a3)
    80002e78:	bfd1                	j	80002e4c <syscall+0x48>
    80002e7a:	37fd                	addiw	a5,a5,-1
    80002e7c:	4761                	li	a4,24
    80002e7e:	00f76b63          	bltu	a4,a5,80002e94 <syscall+0x90>
    80002e82:	00369713          	slli	a4,a3,0x3
    80002e86:	00005797          	auipc	a5,0x5
    80002e8a:	5ca78793          	addi	a5,a5,1482 # 80008450 <syscalls>
    80002e8e:	97ba                	add	a5,a5,a4
    80002e90:	6398                	ld	a4,0(a5)
    80002e92:	ff4d                	bnez	a4,80002e4c <syscall+0x48>
    printf("%d %s: unknown sys call %d\n",
    80002e94:	17848613          	addi	a2,s1,376
    80002e98:	588c                	lw	a1,48(s1)
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	57e50513          	addi	a0,a0,1406 # 80008418 <states.0+0x150>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	6e6080e7          	jalr	1766(ra) # 80000588 <printf>
    p->trapframe->a0 = -1;
    80002eaa:	70bc                	ld	a5,96(s1)
    80002eac:	577d                	li	a4,-1
    80002eae:	fbb8                	sd	a4,112(a5)
}
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6902                	ld	s2,0(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret

0000000080002ebc <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002ebc:	1101                	addi	sp,sp,-32
    80002ebe:	ec06                	sd	ra,24(sp)
    80002ec0:	e822                	sd	s0,16(sp)
    80002ec2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ec4:	fec40593          	addi	a1,s0,-20
    80002ec8:	4501                	li	a0,0
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	e74080e7          	jalr	-396(ra) # 80002d3e <argint>
  exit(n);
    80002ed2:	fec42503          	lw	a0,-20(s0)
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	2da080e7          	jalr	730(ra) # 800021b0 <exit>
  return 0; // not reached
}
    80002ede:	4501                	li	a0,0
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret

0000000080002ee8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ee8:	1141                	addi	sp,sp,-16
    80002eea:	e406                	sd	ra,8(sp)
    80002eec:	e022                	sd	s0,0(sp)
    80002eee:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	abc080e7          	jalr	-1348(ra) # 800019ac <myproc>
}
    80002ef8:	5908                	lw	a0,48(a0)
    80002efa:	60a2                	ld	ra,8(sp)
    80002efc:	6402                	ld	s0,0(sp)
    80002efe:	0141                	addi	sp,sp,16
    80002f00:	8082                	ret

0000000080002f02 <sys_fork>:

uint64
sys_fork(void)
{
    80002f02:	1141                	addi	sp,sp,-16
    80002f04:	e406                	sd	ra,8(sp)
    80002f06:	e022                	sd	s0,0(sp)
    80002f08:	0800                	addi	s0,sp,16
  return fork();
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	e80080e7          	jalr	-384(ra) # 80001d8a <fork>
}
    80002f12:	60a2                	ld	ra,8(sp)
    80002f14:	6402                	ld	s0,0(sp)
    80002f16:	0141                	addi	sp,sp,16
    80002f18:	8082                	ret

0000000080002f1a <sys_wait>:

uint64
sys_wait(void)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f22:	fe840593          	addi	a1,s0,-24
    80002f26:	4501                	li	a0,0
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	e36080e7          	jalr	-458(ra) # 80002d5e <argaddr>
  return wait(p);
    80002f30:	fe843503          	ld	a0,-24(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	42e080e7          	jalr	1070(ra) # 80002362 <wait>
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	6105                	addi	sp,sp,32
    80002f42:	8082                	ret

0000000080002f44 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f44:	7179                	addi	sp,sp,-48
    80002f46:	f406                	sd	ra,40(sp)
    80002f48:	f022                	sd	s0,32(sp)
    80002f4a:	ec26                	sd	s1,24(sp)
    80002f4c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f4e:	fdc40593          	addi	a1,s0,-36
    80002f52:	4501                	li	a0,0
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	dea080e7          	jalr	-534(ra) # 80002d3e <argint>
  addr = myproc()->sz;
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	a50080e7          	jalr	-1456(ra) # 800019ac <myproc>
    80002f64:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002f66:	fdc42503          	lw	a0,-36(s0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	dc4080e7          	jalr	-572(ra) # 80001d2e <growproc>
    80002f72:	00054863          	bltz	a0,80002f82 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f76:	8526                	mv	a0,s1
    80002f78:	70a2                	ld	ra,40(sp)
    80002f7a:	7402                	ld	s0,32(sp)
    80002f7c:	64e2                	ld	s1,24(sp)
    80002f7e:	6145                	addi	sp,sp,48
    80002f80:	8082                	ret
    return -1;
    80002f82:	54fd                	li	s1,-1
    80002f84:	bfcd                	j	80002f76 <sys_sbrk+0x32>

0000000080002f86 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f86:	7139                	addi	sp,sp,-64
    80002f88:	fc06                	sd	ra,56(sp)
    80002f8a:	f822                	sd	s0,48(sp)
    80002f8c:	f426                	sd	s1,40(sp)
    80002f8e:	f04a                	sd	s2,32(sp)
    80002f90:	ec4e                	sd	s3,24(sp)
    80002f92:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f94:	fcc40593          	addi	a1,s0,-52
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	da4080e7          	jalr	-604(ra) # 80002d3e <argint>
  acquire(&tickslock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	5de50513          	addi	a0,a0,1502 # 80017580 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c2c080e7          	jalr	-980(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002fb2:	00006917          	auipc	s2,0x6
    80002fb6:	92e92903          	lw	s2,-1746(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80002fba:	fcc42783          	lw	a5,-52(s0)
    80002fbe:	cf9d                	beqz	a5,80002ffc <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fc0:	00014997          	auipc	s3,0x14
    80002fc4:	5c098993          	addi	s3,s3,1472 # 80017580 <tickslock>
    80002fc8:	00006497          	auipc	s1,0x6
    80002fcc:	91848493          	addi	s1,s1,-1768 # 800088e0 <ticks>
    if (killed(myproc()))
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	9dc080e7          	jalr	-1572(ra) # 800019ac <myproc>
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	358080e7          	jalr	856(ra) # 80002330 <killed>
    80002fe0:	ed15                	bnez	a0,8000301c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fe2:	85ce                	mv	a1,s3
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	096080e7          	jalr	150(ra) # 8000207c <sleep>
  while (ticks - ticks0 < n)
    80002fee:	409c                	lw	a5,0(s1)
    80002ff0:	412787bb          	subw	a5,a5,s2
    80002ff4:	fcc42703          	lw	a4,-52(s0)
    80002ff8:	fce7ece3          	bltu	a5,a4,80002fd0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	58450513          	addi	a0,a0,1412 # 80017580 <tickslock>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	c86080e7          	jalr	-890(ra) # 80000c8a <release>
  return 0;
    8000300c:	4501                	li	a0,0
}
    8000300e:	70e2                	ld	ra,56(sp)
    80003010:	7442                	ld	s0,48(sp)
    80003012:	74a2                	ld	s1,40(sp)
    80003014:	7902                	ld	s2,32(sp)
    80003016:	69e2                	ld	s3,24(sp)
    80003018:	6121                	addi	sp,sp,64
    8000301a:	8082                	ret
      release(&tickslock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	56450513          	addi	a0,a0,1380 # 80017580 <tickslock>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c66080e7          	jalr	-922(ra) # 80000c8a <release>
      return -1;
    8000302c:	557d                	li	a0,-1
    8000302e:	b7c5                	j	8000300e <sys_sleep+0x88>

0000000080003030 <sys_kill>:

uint64
sys_kill(void)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003038:	fec40593          	addi	a1,s0,-20
    8000303c:	4501                	li	a0,0
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	d00080e7          	jalr	-768(ra) # 80002d3e <argint>
  return kill(pid);
    80003046:	fec42503          	lw	a0,-20(s0)
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	248080e7          	jalr	584(ra) # 80002292 <kill>
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret

000000008000305a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	51c50513          	addi	a0,a0,1308 # 80017580 <tickslock>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	b6a080e7          	jalr	-1174(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003074:	00006497          	auipc	s1,0x6
    80003078:	86c4a483          	lw	s1,-1940(s1) # 800088e0 <ticks>
  release(&tickslock);
    8000307c:	00014517          	auipc	a0,0x14
    80003080:	50450513          	addi	a0,a0,1284 # 80017580 <tickslock>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	c06080e7          	jalr	-1018(ra) # 80000c8a <release>
  return xticks;
}
    8000308c:	02049513          	slli	a0,s1,0x20
    80003090:	9101                	srli	a0,a0,0x20
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000309c:	7139                	addi	sp,sp,-64
    8000309e:	fc06                	sd	ra,56(sp)
    800030a0:	f822                	sd	s0,48(sp)
    800030a2:	f426                	sd	s1,40(sp)
    800030a4:	f04a                	sd	s2,32(sp)
    800030a6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030a8:	fd840593          	addi	a1,s0,-40
    800030ac:	4501                	li	a0,0
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	cb0080e7          	jalr	-848(ra) # 80002d5e <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030b6:	fd040593          	addi	a1,s0,-48
    800030ba:	4505                	li	a0,1
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	ca2080e7          	jalr	-862(ra) # 80002d5e <argaddr>
  argaddr(2, &addr2);
    800030c4:	fc840593          	addi	a1,s0,-56
    800030c8:	4509                	li	a0,2
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	c94080e7          	jalr	-876(ra) # 80002d5e <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030d2:	fc040613          	addi	a2,s0,-64
    800030d6:	fc440593          	addi	a1,s0,-60
    800030da:	fd843503          	ld	a0,-40(s0)
    800030de:	fffff097          	auipc	ra,0xfffff
    800030e2:	50c080e7          	jalr	1292(ra) # 800025ea <waitx>
    800030e6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	8c4080e7          	jalr	-1852(ra) # 800019ac <myproc>
    800030f0:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800030f2:	4691                	li	a3,4
    800030f4:	fc440613          	addi	a2,s0,-60
    800030f8:	fd043583          	ld	a1,-48(s0)
    800030fc:	6d28                	ld	a0,88(a0)
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	56a080e7          	jalr	1386(ra) # 80001668 <copyout>
    return -1;
    80003106:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003108:	00054f63          	bltz	a0,80003126 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000310c:	4691                	li	a3,4
    8000310e:	fc040613          	addi	a2,s0,-64
    80003112:	fc843583          	ld	a1,-56(s0)
    80003116:	6ca8                	ld	a0,88(s1)
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	550080e7          	jalr	1360(ra) # 80001668 <copyout>
    80003120:	00054a63          	bltz	a0,80003134 <sys_waitx+0x98>
    return -1;
  return ret;
    80003124:	87ca                	mv	a5,s2
}
    80003126:	853e                	mv	a0,a5
    80003128:	70e2                	ld	ra,56(sp)
    8000312a:	7442                	ld	s0,48(sp)
    8000312c:	74a2                	ld	s1,40(sp)
    8000312e:	7902                	ld	s2,32(sp)
    80003130:	6121                	addi	sp,sp,64
    80003132:	8082                	ret
    return -1;
    80003134:	57fd                	li	a5,-1
    80003136:	bfc5                	j	80003126 <sys_waitx+0x8a>

0000000080003138 <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    80003138:	1141                	addi	sp,sp,-16
    8000313a:	e406                	sd	ra,8(sp)
    8000313c:	e022                	sd	s0,0(sp)
    8000313e:	0800                	addi	s0,sp,16
  return myproc()->readcount;
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	86c080e7          	jalr	-1940(ra) # 800019ac <myproc>
}
    80003148:	5948                	lw	a0,52(a0)
    8000314a:	60a2                	ld	ra,8(sp)
    8000314c:	6402                	ld	s0,0(sp)
    8000314e:	0141                	addi	sp,sp,16
    80003150:	8082                	ret

0000000080003152 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003152:	7179                	addi	sp,sp,-48
    80003154:	f406                	sd	ra,40(sp)
    80003156:	f022                	sd	s0,32(sp)
    80003158:	ec26                	sd	s1,24(sp)
    8000315a:	e84a                	sd	s2,16(sp)
    8000315c:	e44e                	sd	s3,8(sp)
    8000315e:	e052                	sd	s4,0(sp)
    80003160:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003162:	00005597          	auipc	a1,0x5
    80003166:	3be58593          	addi	a1,a1,958 # 80008520 <syscalls+0xd0>
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	42e50513          	addi	a0,a0,1070 # 80017598 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	9d4080e7          	jalr	-1580(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000317a:	0001c797          	auipc	a5,0x1c
    8000317e:	41e78793          	addi	a5,a5,1054 # 8001f598 <bcache+0x8000>
    80003182:	0001c717          	auipc	a4,0x1c
    80003186:	67e70713          	addi	a4,a4,1662 # 8001f800 <bcache+0x8268>
    8000318a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000318e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003192:	00014497          	auipc	s1,0x14
    80003196:	41e48493          	addi	s1,s1,1054 # 800175b0 <bcache+0x18>
    b->next = bcache.head.next;
    8000319a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000319c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000319e:	00005a17          	auipc	s4,0x5
    800031a2:	38aa0a13          	addi	s4,s4,906 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031a6:	2b893783          	ld	a5,696(s2)
    800031aa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031ac:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031b0:	85d2                	mv	a1,s4
    800031b2:	01048513          	addi	a0,s1,16
    800031b6:	00001097          	auipc	ra,0x1
    800031ba:	4c4080e7          	jalr	1220(ra) # 8000467a <initsleeplock>
    bcache.head.next->prev = b;
    800031be:	2b893783          	ld	a5,696(s2)
    800031c2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031c4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031c8:	45848493          	addi	s1,s1,1112
    800031cc:	fd349de3          	bne	s1,s3,800031a6 <binit+0x54>
  }
}
    800031d0:	70a2                	ld	ra,40(sp)
    800031d2:	7402                	ld	s0,32(sp)
    800031d4:	64e2                	ld	s1,24(sp)
    800031d6:	6942                	ld	s2,16(sp)
    800031d8:	69a2                	ld	s3,8(sp)
    800031da:	6a02                	ld	s4,0(sp)
    800031dc:	6145                	addi	sp,sp,48
    800031de:	8082                	ret

00000000800031e0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031e0:	7179                	addi	sp,sp,-48
    800031e2:	f406                	sd	ra,40(sp)
    800031e4:	f022                	sd	s0,32(sp)
    800031e6:	ec26                	sd	s1,24(sp)
    800031e8:	e84a                	sd	s2,16(sp)
    800031ea:	e44e                	sd	s3,8(sp)
    800031ec:	1800                	addi	s0,sp,48
    800031ee:	892a                	mv	s2,a0
    800031f0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	3a650513          	addi	a0,a0,934 # 80017598 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	9dc080e7          	jalr	-1572(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003202:	0001c497          	auipc	s1,0x1c
    80003206:	64e4b483          	ld	s1,1614(s1) # 8001f850 <bcache+0x82b8>
    8000320a:	0001c797          	auipc	a5,0x1c
    8000320e:	5f678793          	addi	a5,a5,1526 # 8001f800 <bcache+0x8268>
    80003212:	02f48f63          	beq	s1,a5,80003250 <bread+0x70>
    80003216:	873e                	mv	a4,a5
    80003218:	a021                	j	80003220 <bread+0x40>
    8000321a:	68a4                	ld	s1,80(s1)
    8000321c:	02e48a63          	beq	s1,a4,80003250 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003220:	449c                	lw	a5,8(s1)
    80003222:	ff279ce3          	bne	a5,s2,8000321a <bread+0x3a>
    80003226:	44dc                	lw	a5,12(s1)
    80003228:	ff3799e3          	bne	a5,s3,8000321a <bread+0x3a>
      b->refcnt++;
    8000322c:	40bc                	lw	a5,64(s1)
    8000322e:	2785                	addiw	a5,a5,1
    80003230:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003232:	00014517          	auipc	a0,0x14
    80003236:	36650513          	addi	a0,a0,870 # 80017598 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	a50080e7          	jalr	-1456(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003242:	01048513          	addi	a0,s1,16
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	46e080e7          	jalr	1134(ra) # 800046b4 <acquiresleep>
      return b;
    8000324e:	a8b9                	j	800032ac <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003250:	0001c497          	auipc	s1,0x1c
    80003254:	5f84b483          	ld	s1,1528(s1) # 8001f848 <bcache+0x82b0>
    80003258:	0001c797          	auipc	a5,0x1c
    8000325c:	5a878793          	addi	a5,a5,1448 # 8001f800 <bcache+0x8268>
    80003260:	00f48863          	beq	s1,a5,80003270 <bread+0x90>
    80003264:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003266:	40bc                	lw	a5,64(s1)
    80003268:	cf81                	beqz	a5,80003280 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000326a:	64a4                	ld	s1,72(s1)
    8000326c:	fee49de3          	bne	s1,a4,80003266 <bread+0x86>
  panic("bget: no buffers");
    80003270:	00005517          	auipc	a0,0x5
    80003274:	2c050513          	addi	a0,a0,704 # 80008530 <syscalls+0xe0>
    80003278:	ffffd097          	auipc	ra,0xffffd
    8000327c:	2c6080e7          	jalr	710(ra) # 8000053e <panic>
      b->dev = dev;
    80003280:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003284:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003288:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000328c:	4785                	li	a5,1
    8000328e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003290:	00014517          	auipc	a0,0x14
    80003294:	30850513          	addi	a0,a0,776 # 80017598 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	9f2080e7          	jalr	-1550(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032a0:	01048513          	addi	a0,s1,16
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	410080e7          	jalr	1040(ra) # 800046b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032ac:	409c                	lw	a5,0(s1)
    800032ae:	cb89                	beqz	a5,800032c0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032b0:	8526                	mv	a0,s1
    800032b2:	70a2                	ld	ra,40(sp)
    800032b4:	7402                	ld	s0,32(sp)
    800032b6:	64e2                	ld	s1,24(sp)
    800032b8:	6942                	ld	s2,16(sp)
    800032ba:	69a2                	ld	s3,8(sp)
    800032bc:	6145                	addi	sp,sp,48
    800032be:	8082                	ret
    virtio_disk_rw(b, 0);
    800032c0:	4581                	li	a1,0
    800032c2:	8526                	mv	a0,s1
    800032c4:	00003097          	auipc	ra,0x3
    800032c8:	fd0080e7          	jalr	-48(ra) # 80006294 <virtio_disk_rw>
    b->valid = 1;
    800032cc:	4785                	li	a5,1
    800032ce:	c09c                	sw	a5,0(s1)
  return b;
    800032d0:	b7c5                	j	800032b0 <bread+0xd0>

00000000800032d2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	e426                	sd	s1,8(sp)
    800032da:	1000                	addi	s0,sp,32
    800032dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032de:	0541                	addi	a0,a0,16
    800032e0:	00001097          	auipc	ra,0x1
    800032e4:	46e080e7          	jalr	1134(ra) # 8000474e <holdingsleep>
    800032e8:	cd01                	beqz	a0,80003300 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032ea:	4585                	li	a1,1
    800032ec:	8526                	mv	a0,s1
    800032ee:	00003097          	auipc	ra,0x3
    800032f2:	fa6080e7          	jalr	-90(ra) # 80006294 <virtio_disk_rw>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret
    panic("bwrite");
    80003300:	00005517          	auipc	a0,0x5
    80003304:	24850513          	addi	a0,a0,584 # 80008548 <syscalls+0xf8>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	236080e7          	jalr	566(ra) # 8000053e <panic>

0000000080003310 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	e426                	sd	s1,8(sp)
    80003318:	e04a                	sd	s2,0(sp)
    8000331a:	1000                	addi	s0,sp,32
    8000331c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000331e:	01050913          	addi	s2,a0,16
    80003322:	854a                	mv	a0,s2
    80003324:	00001097          	auipc	ra,0x1
    80003328:	42a080e7          	jalr	1066(ra) # 8000474e <holdingsleep>
    8000332c:	c92d                	beqz	a0,8000339e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000332e:	854a                	mv	a0,s2
    80003330:	00001097          	auipc	ra,0x1
    80003334:	3da080e7          	jalr	986(ra) # 8000470a <releasesleep>

  acquire(&bcache.lock);
    80003338:	00014517          	auipc	a0,0x14
    8000333c:	26050513          	addi	a0,a0,608 # 80017598 <bcache>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	896080e7          	jalr	-1898(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003348:	40bc                	lw	a5,64(s1)
    8000334a:	37fd                	addiw	a5,a5,-1
    8000334c:	0007871b          	sext.w	a4,a5
    80003350:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003352:	eb05                	bnez	a4,80003382 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003354:	68bc                	ld	a5,80(s1)
    80003356:	64b8                	ld	a4,72(s1)
    80003358:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000335a:	64bc                	ld	a5,72(s1)
    8000335c:	68b8                	ld	a4,80(s1)
    8000335e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003360:	0001c797          	auipc	a5,0x1c
    80003364:	23878793          	addi	a5,a5,568 # 8001f598 <bcache+0x8000>
    80003368:	2b87b703          	ld	a4,696(a5)
    8000336c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000336e:	0001c717          	auipc	a4,0x1c
    80003372:	49270713          	addi	a4,a4,1170 # 8001f800 <bcache+0x8268>
    80003376:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003378:	2b87b703          	ld	a4,696(a5)
    8000337c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000337e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003382:	00014517          	auipc	a0,0x14
    80003386:	21650513          	addi	a0,a0,534 # 80017598 <bcache>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	900080e7          	jalr	-1792(ra) # 80000c8a <release>
}
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	64a2                	ld	s1,8(sp)
    80003398:	6902                	ld	s2,0(sp)
    8000339a:	6105                	addi	sp,sp,32
    8000339c:	8082                	ret
    panic("brelse");
    8000339e:	00005517          	auipc	a0,0x5
    800033a2:	1b250513          	addi	a0,a0,434 # 80008550 <syscalls+0x100>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	198080e7          	jalr	408(ra) # 8000053e <panic>

00000000800033ae <bpin>:

void
bpin(struct buf *b) {
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	1000                	addi	s0,sp,32
    800033b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ba:	00014517          	auipc	a0,0x14
    800033be:	1de50513          	addi	a0,a0,478 # 80017598 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	814080e7          	jalr	-2028(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d0:	00014517          	auipc	a0,0x14
    800033d4:	1c850513          	addi	a0,a0,456 # 80017598 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8b2080e7          	jalr	-1870(ra) # 80000c8a <release>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6105                	addi	sp,sp,32
    800033e8:	8082                	ret

00000000800033ea <bunpin>:

void
bunpin(struct buf *b) {
    800033ea:	1101                	addi	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	e426                	sd	s1,8(sp)
    800033f2:	1000                	addi	s0,sp,32
    800033f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033f6:	00014517          	auipc	a0,0x14
    800033fa:	1a250513          	addi	a0,a0,418 # 80017598 <bcache>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	7d8080e7          	jalr	2008(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003406:	40bc                	lw	a5,64(s1)
    80003408:	37fd                	addiw	a5,a5,-1
    8000340a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000340c:	00014517          	auipc	a0,0x14
    80003410:	18c50513          	addi	a0,a0,396 # 80017598 <bcache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	e426                	sd	s1,8(sp)
    8000342e:	e04a                	sd	s2,0(sp)
    80003430:	1000                	addi	s0,sp,32
    80003432:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003434:	00d5d59b          	srliw	a1,a1,0xd
    80003438:	0001d797          	auipc	a5,0x1d
    8000343c:	83c7a783          	lw	a5,-1988(a5) # 8001fc74 <sb+0x1c>
    80003440:	9dbd                	addw	a1,a1,a5
    80003442:	00000097          	auipc	ra,0x0
    80003446:	d9e080e7          	jalr	-610(ra) # 800031e0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000344a:	0074f713          	andi	a4,s1,7
    8000344e:	4785                	li	a5,1
    80003450:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003454:	14ce                	slli	s1,s1,0x33
    80003456:	90d9                	srli	s1,s1,0x36
    80003458:	00950733          	add	a4,a0,s1
    8000345c:	05874703          	lbu	a4,88(a4)
    80003460:	00e7f6b3          	and	a3,a5,a4
    80003464:	c69d                	beqz	a3,80003492 <bfree+0x6c>
    80003466:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003468:	94aa                	add	s1,s1,a0
    8000346a:	fff7c793          	not	a5,a5
    8000346e:	8ff9                	and	a5,a5,a4
    80003470:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003474:	00001097          	auipc	ra,0x1
    80003478:	120080e7          	jalr	288(ra) # 80004594 <log_write>
  brelse(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e92080e7          	jalr	-366(ra) # 80003310 <brelse>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6902                	ld	s2,0(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret
    panic("freeing free block");
    80003492:	00005517          	auipc	a0,0x5
    80003496:	0c650513          	addi	a0,a0,198 # 80008558 <syscalls+0x108>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>

00000000800034a2 <balloc>:
{
    800034a2:	711d                	addi	sp,sp,-96
    800034a4:	ec86                	sd	ra,88(sp)
    800034a6:	e8a2                	sd	s0,80(sp)
    800034a8:	e4a6                	sd	s1,72(sp)
    800034aa:	e0ca                	sd	s2,64(sp)
    800034ac:	fc4e                	sd	s3,56(sp)
    800034ae:	f852                	sd	s4,48(sp)
    800034b0:	f456                	sd	s5,40(sp)
    800034b2:	f05a                	sd	s6,32(sp)
    800034b4:	ec5e                	sd	s7,24(sp)
    800034b6:	e862                	sd	s8,16(sp)
    800034b8:	e466                	sd	s9,8(sp)
    800034ba:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034bc:	0001c797          	auipc	a5,0x1c
    800034c0:	7a07a783          	lw	a5,1952(a5) # 8001fc5c <sb+0x4>
    800034c4:	10078163          	beqz	a5,800035c6 <balloc+0x124>
    800034c8:	8baa                	mv	s7,a0
    800034ca:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034cc:	0001cb17          	auipc	s6,0x1c
    800034d0:	78cb0b13          	addi	s6,s6,1932 # 8001fc58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034d6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034da:	6c89                	lui	s9,0x2
    800034dc:	a061                	j	80003564 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034de:	974a                	add	a4,a4,s2
    800034e0:	8fd5                	or	a5,a5,a3
    800034e2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	0ac080e7          	jalr	172(ra) # 80004594 <log_write>
        brelse(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e1e080e7          	jalr	-482(ra) # 80003310 <brelse>
  bp = bread(dev, bno);
    800034fa:	85a6                	mv	a1,s1
    800034fc:	855e                	mv	a0,s7
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	ce2080e7          	jalr	-798(ra) # 800031e0 <bread>
    80003506:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003508:	40000613          	li	a2,1024
    8000350c:	4581                	li	a1,0
    8000350e:	05850513          	addi	a0,a0,88
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	7c0080e7          	jalr	1984(ra) # 80000cd2 <memset>
  log_write(bp);
    8000351a:	854a                	mv	a0,s2
    8000351c:	00001097          	auipc	ra,0x1
    80003520:	078080e7          	jalr	120(ra) # 80004594 <log_write>
  brelse(bp);
    80003524:	854a                	mv	a0,s2
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	dea080e7          	jalr	-534(ra) # 80003310 <brelse>
}
    8000352e:	8526                	mv	a0,s1
    80003530:	60e6                	ld	ra,88(sp)
    80003532:	6446                	ld	s0,80(sp)
    80003534:	64a6                	ld	s1,72(sp)
    80003536:	6906                	ld	s2,64(sp)
    80003538:	79e2                	ld	s3,56(sp)
    8000353a:	7a42                	ld	s4,48(sp)
    8000353c:	7aa2                	ld	s5,40(sp)
    8000353e:	7b02                	ld	s6,32(sp)
    80003540:	6be2                	ld	s7,24(sp)
    80003542:	6c42                	ld	s8,16(sp)
    80003544:	6ca2                	ld	s9,8(sp)
    80003546:	6125                	addi	sp,sp,96
    80003548:	8082                	ret
    brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	dc4080e7          	jalr	-572(ra) # 80003310 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003554:	015c87bb          	addw	a5,s9,s5
    80003558:	00078a9b          	sext.w	s5,a5
    8000355c:	004b2703          	lw	a4,4(s6)
    80003560:	06eaf363          	bgeu	s5,a4,800035c6 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003564:	41fad79b          	sraiw	a5,s5,0x1f
    80003568:	0137d79b          	srliw	a5,a5,0x13
    8000356c:	015787bb          	addw	a5,a5,s5
    80003570:	40d7d79b          	sraiw	a5,a5,0xd
    80003574:	01cb2583          	lw	a1,28(s6)
    80003578:	9dbd                	addw	a1,a1,a5
    8000357a:	855e                	mv	a0,s7
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	c64080e7          	jalr	-924(ra) # 800031e0 <bread>
    80003584:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003586:	004b2503          	lw	a0,4(s6)
    8000358a:	000a849b          	sext.w	s1,s5
    8000358e:	8662                	mv	a2,s8
    80003590:	faa4fde3          	bgeu	s1,a0,8000354a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003594:	41f6579b          	sraiw	a5,a2,0x1f
    80003598:	01d7d69b          	srliw	a3,a5,0x1d
    8000359c:	00c6873b          	addw	a4,a3,a2
    800035a0:	00777793          	andi	a5,a4,7
    800035a4:	9f95                	subw	a5,a5,a3
    800035a6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035aa:	4037571b          	sraiw	a4,a4,0x3
    800035ae:	00e906b3          	add	a3,s2,a4
    800035b2:	0586c683          	lbu	a3,88(a3)
    800035b6:	00d7f5b3          	and	a1,a5,a3
    800035ba:	d195                	beqz	a1,800034de <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035bc:	2605                	addiw	a2,a2,1
    800035be:	2485                	addiw	s1,s1,1
    800035c0:	fd4618e3          	bne	a2,s4,80003590 <balloc+0xee>
    800035c4:	b759                	j	8000354a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800035c6:	00005517          	auipc	a0,0x5
    800035ca:	faa50513          	addi	a0,a0,-86 # 80008570 <syscalls+0x120>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	fba080e7          	jalr	-70(ra) # 80000588 <printf>
  return 0;
    800035d6:	4481                	li	s1,0
    800035d8:	bf99                	j	8000352e <balloc+0x8c>

00000000800035da <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	e052                	sd	s4,0(sp)
    800035e8:	1800                	addi	s0,sp,48
    800035ea:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035ec:	47ad                	li	a5,11
    800035ee:	02b7e763          	bltu	a5,a1,8000361c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800035f2:	02059493          	slli	s1,a1,0x20
    800035f6:	9081                	srli	s1,s1,0x20
    800035f8:	048a                	slli	s1,s1,0x2
    800035fa:	94aa                	add	s1,s1,a0
    800035fc:	0504a903          	lw	s2,80(s1)
    80003600:	06091e63          	bnez	s2,8000367c <bmap+0xa2>
      addr = balloc(ip->dev);
    80003604:	4108                	lw	a0,0(a0)
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	e9c080e7          	jalr	-356(ra) # 800034a2 <balloc>
    8000360e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003612:	06090563          	beqz	s2,8000367c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003616:	0524a823          	sw	s2,80(s1)
    8000361a:	a08d                	j	8000367c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000361c:	ff45849b          	addiw	s1,a1,-12
    80003620:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003624:	0ff00793          	li	a5,255
    80003628:	08e7e563          	bltu	a5,a4,800036b2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000362c:	08052903          	lw	s2,128(a0)
    80003630:	00091d63          	bnez	s2,8000364a <bmap+0x70>
      addr = balloc(ip->dev);
    80003634:	4108                	lw	a0,0(a0)
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	e6c080e7          	jalr	-404(ra) # 800034a2 <balloc>
    8000363e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003642:	02090d63          	beqz	s2,8000367c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003646:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000364a:	85ca                	mv	a1,s2
    8000364c:	0009a503          	lw	a0,0(s3)
    80003650:	00000097          	auipc	ra,0x0
    80003654:	b90080e7          	jalr	-1136(ra) # 800031e0 <bread>
    80003658:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000365a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000365e:	02049593          	slli	a1,s1,0x20
    80003662:	9181                	srli	a1,a1,0x20
    80003664:	058a                	slli	a1,a1,0x2
    80003666:	00b784b3          	add	s1,a5,a1
    8000366a:	0004a903          	lw	s2,0(s1)
    8000366e:	02090063          	beqz	s2,8000368e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003672:	8552                	mv	a0,s4
    80003674:	00000097          	auipc	ra,0x0
    80003678:	c9c080e7          	jalr	-868(ra) # 80003310 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000367c:	854a                	mv	a0,s2
    8000367e:	70a2                	ld	ra,40(sp)
    80003680:	7402                	ld	s0,32(sp)
    80003682:	64e2                	ld	s1,24(sp)
    80003684:	6942                	ld	s2,16(sp)
    80003686:	69a2                	ld	s3,8(sp)
    80003688:	6a02                	ld	s4,0(sp)
    8000368a:	6145                	addi	sp,sp,48
    8000368c:	8082                	ret
      addr = balloc(ip->dev);
    8000368e:	0009a503          	lw	a0,0(s3)
    80003692:	00000097          	auipc	ra,0x0
    80003696:	e10080e7          	jalr	-496(ra) # 800034a2 <balloc>
    8000369a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000369e:	fc090ae3          	beqz	s2,80003672 <bmap+0x98>
        a[bn] = addr;
    800036a2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036a6:	8552                	mv	a0,s4
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	eec080e7          	jalr	-276(ra) # 80004594 <log_write>
    800036b0:	b7c9                	j	80003672 <bmap+0x98>
  panic("bmap: out of range");
    800036b2:	00005517          	auipc	a0,0x5
    800036b6:	ed650513          	addi	a0,a0,-298 # 80008588 <syscalls+0x138>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	e84080e7          	jalr	-380(ra) # 8000053e <panic>

00000000800036c2 <iget>:
{
    800036c2:	7179                	addi	sp,sp,-48
    800036c4:	f406                	sd	ra,40(sp)
    800036c6:	f022                	sd	s0,32(sp)
    800036c8:	ec26                	sd	s1,24(sp)
    800036ca:	e84a                	sd	s2,16(sp)
    800036cc:	e44e                	sd	s3,8(sp)
    800036ce:	e052                	sd	s4,0(sp)
    800036d0:	1800                	addi	s0,sp,48
    800036d2:	89aa                	mv	s3,a0
    800036d4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036d6:	0001c517          	auipc	a0,0x1c
    800036da:	5a250513          	addi	a0,a0,1442 # 8001fc78 <itable>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	4f8080e7          	jalr	1272(ra) # 80000bd6 <acquire>
  empty = 0;
    800036e6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036e8:	0001c497          	auipc	s1,0x1c
    800036ec:	5a848493          	addi	s1,s1,1448 # 8001fc90 <itable+0x18>
    800036f0:	0001e697          	auipc	a3,0x1e
    800036f4:	03068693          	addi	a3,a3,48 # 80021720 <log>
    800036f8:	a039                	j	80003706 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036fa:	02090b63          	beqz	s2,80003730 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036fe:	08848493          	addi	s1,s1,136
    80003702:	02d48a63          	beq	s1,a3,80003736 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003706:	449c                	lw	a5,8(s1)
    80003708:	fef059e3          	blez	a5,800036fa <iget+0x38>
    8000370c:	4098                	lw	a4,0(s1)
    8000370e:	ff3716e3          	bne	a4,s3,800036fa <iget+0x38>
    80003712:	40d8                	lw	a4,4(s1)
    80003714:	ff4713e3          	bne	a4,s4,800036fa <iget+0x38>
      ip->ref++;
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000371c:	0001c517          	auipc	a0,0x1c
    80003720:	55c50513          	addi	a0,a0,1372 # 8001fc78 <itable>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	566080e7          	jalr	1382(ra) # 80000c8a <release>
      return ip;
    8000372c:	8926                	mv	s2,s1
    8000372e:	a03d                	j	8000375c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003730:	f7f9                	bnez	a5,800036fe <iget+0x3c>
    80003732:	8926                	mv	s2,s1
    80003734:	b7e9                	j	800036fe <iget+0x3c>
  if(empty == 0)
    80003736:	02090c63          	beqz	s2,8000376e <iget+0xac>
  ip->dev = dev;
    8000373a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000373e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003742:	4785                	li	a5,1
    80003744:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003748:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000374c:	0001c517          	auipc	a0,0x1c
    80003750:	52c50513          	addi	a0,a0,1324 # 8001fc78 <itable>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	536080e7          	jalr	1334(ra) # 80000c8a <release>
}
    8000375c:	854a                	mv	a0,s2
    8000375e:	70a2                	ld	ra,40(sp)
    80003760:	7402                	ld	s0,32(sp)
    80003762:	64e2                	ld	s1,24(sp)
    80003764:	6942                	ld	s2,16(sp)
    80003766:	69a2                	ld	s3,8(sp)
    80003768:	6a02                	ld	s4,0(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret
    panic("iget: no inodes");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	e3250513          	addi	a0,a0,-462 # 800085a0 <syscalls+0x150>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>

000000008000377e <fsinit>:
fsinit(int dev) {
    8000377e:	7179                	addi	sp,sp,-48
    80003780:	f406                	sd	ra,40(sp)
    80003782:	f022                	sd	s0,32(sp)
    80003784:	ec26                	sd	s1,24(sp)
    80003786:	e84a                	sd	s2,16(sp)
    80003788:	e44e                	sd	s3,8(sp)
    8000378a:	1800                	addi	s0,sp,48
    8000378c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000378e:	4585                	li	a1,1
    80003790:	00000097          	auipc	ra,0x0
    80003794:	a50080e7          	jalr	-1456(ra) # 800031e0 <bread>
    80003798:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000379a:	0001c997          	auipc	s3,0x1c
    8000379e:	4be98993          	addi	s3,s3,1214 # 8001fc58 <sb>
    800037a2:	02000613          	li	a2,32
    800037a6:	05850593          	addi	a1,a0,88
    800037aa:	854e                	mv	a0,s3
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	582080e7          	jalr	1410(ra) # 80000d2e <memmove>
  brelse(bp);
    800037b4:	8526                	mv	a0,s1
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	b5a080e7          	jalr	-1190(ra) # 80003310 <brelse>
  if(sb.magic != FSMAGIC)
    800037be:	0009a703          	lw	a4,0(s3)
    800037c2:	102037b7          	lui	a5,0x10203
    800037c6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037ca:	02f71263          	bne	a4,a5,800037ee <fsinit+0x70>
  initlog(dev, &sb);
    800037ce:	0001c597          	auipc	a1,0x1c
    800037d2:	48a58593          	addi	a1,a1,1162 # 8001fc58 <sb>
    800037d6:	854a                	mv	a0,s2
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	b40080e7          	jalr	-1216(ra) # 80004318 <initlog>
}
    800037e0:	70a2                	ld	ra,40(sp)
    800037e2:	7402                	ld	s0,32(sp)
    800037e4:	64e2                	ld	s1,24(sp)
    800037e6:	6942                	ld	s2,16(sp)
    800037e8:	69a2                	ld	s3,8(sp)
    800037ea:	6145                	addi	sp,sp,48
    800037ec:	8082                	ret
    panic("invalid file system");
    800037ee:	00005517          	auipc	a0,0x5
    800037f2:	dc250513          	addi	a0,a0,-574 # 800085b0 <syscalls+0x160>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>

00000000800037fe <iinit>:
{
    800037fe:	7179                	addi	sp,sp,-48
    80003800:	f406                	sd	ra,40(sp)
    80003802:	f022                	sd	s0,32(sp)
    80003804:	ec26                	sd	s1,24(sp)
    80003806:	e84a                	sd	s2,16(sp)
    80003808:	e44e                	sd	s3,8(sp)
    8000380a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000380c:	00005597          	auipc	a1,0x5
    80003810:	dbc58593          	addi	a1,a1,-580 # 800085c8 <syscalls+0x178>
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	46450513          	addi	a0,a0,1124 # 8001fc78 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	32a080e7          	jalr	810(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003824:	0001c497          	auipc	s1,0x1c
    80003828:	47c48493          	addi	s1,s1,1148 # 8001fca0 <itable+0x28>
    8000382c:	0001e997          	auipc	s3,0x1e
    80003830:	f0498993          	addi	s3,s3,-252 # 80021730 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003834:	00005917          	auipc	s2,0x5
    80003838:	d9c90913          	addi	s2,s2,-612 # 800085d0 <syscalls+0x180>
    8000383c:	85ca                	mv	a1,s2
    8000383e:	8526                	mv	a0,s1
    80003840:	00001097          	auipc	ra,0x1
    80003844:	e3a080e7          	jalr	-454(ra) # 8000467a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003848:	08848493          	addi	s1,s1,136
    8000384c:	ff3498e3          	bne	s1,s3,8000383c <iinit+0x3e>
}
    80003850:	70a2                	ld	ra,40(sp)
    80003852:	7402                	ld	s0,32(sp)
    80003854:	64e2                	ld	s1,24(sp)
    80003856:	6942                	ld	s2,16(sp)
    80003858:	69a2                	ld	s3,8(sp)
    8000385a:	6145                	addi	sp,sp,48
    8000385c:	8082                	ret

000000008000385e <ialloc>:
{
    8000385e:	715d                	addi	sp,sp,-80
    80003860:	e486                	sd	ra,72(sp)
    80003862:	e0a2                	sd	s0,64(sp)
    80003864:	fc26                	sd	s1,56(sp)
    80003866:	f84a                	sd	s2,48(sp)
    80003868:	f44e                	sd	s3,40(sp)
    8000386a:	f052                	sd	s4,32(sp)
    8000386c:	ec56                	sd	s5,24(sp)
    8000386e:	e85a                	sd	s6,16(sp)
    80003870:	e45e                	sd	s7,8(sp)
    80003872:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003874:	0001c717          	auipc	a4,0x1c
    80003878:	3f072703          	lw	a4,1008(a4) # 8001fc64 <sb+0xc>
    8000387c:	4785                	li	a5,1
    8000387e:	04e7fa63          	bgeu	a5,a4,800038d2 <ialloc+0x74>
    80003882:	8aaa                	mv	s5,a0
    80003884:	8bae                	mv	s7,a1
    80003886:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003888:	0001ca17          	auipc	s4,0x1c
    8000388c:	3d0a0a13          	addi	s4,s4,976 # 8001fc58 <sb>
    80003890:	00048b1b          	sext.w	s6,s1
    80003894:	0044d793          	srli	a5,s1,0x4
    80003898:	018a2583          	lw	a1,24(s4)
    8000389c:	9dbd                	addw	a1,a1,a5
    8000389e:	8556                	mv	a0,s5
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	940080e7          	jalr	-1728(ra) # 800031e0 <bread>
    800038a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038aa:	05850993          	addi	s3,a0,88
    800038ae:	00f4f793          	andi	a5,s1,15
    800038b2:	079a                	slli	a5,a5,0x6
    800038b4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038b6:	00099783          	lh	a5,0(s3)
    800038ba:	c3a1                	beqz	a5,800038fa <ialloc+0x9c>
    brelse(bp);
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	a54080e7          	jalr	-1452(ra) # 80003310 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038c4:	0485                	addi	s1,s1,1
    800038c6:	00ca2703          	lw	a4,12(s4)
    800038ca:	0004879b          	sext.w	a5,s1
    800038ce:	fce7e1e3          	bltu	a5,a4,80003890 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038d2:	00005517          	auipc	a0,0x5
    800038d6:	d0650513          	addi	a0,a0,-762 # 800085d8 <syscalls+0x188>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	cae080e7          	jalr	-850(ra) # 80000588 <printf>
  return 0;
    800038e2:	4501                	li	a0,0
}
    800038e4:	60a6                	ld	ra,72(sp)
    800038e6:	6406                	ld	s0,64(sp)
    800038e8:	74e2                	ld	s1,56(sp)
    800038ea:	7942                	ld	s2,48(sp)
    800038ec:	79a2                	ld	s3,40(sp)
    800038ee:	7a02                	ld	s4,32(sp)
    800038f0:	6ae2                	ld	s5,24(sp)
    800038f2:	6b42                	ld	s6,16(sp)
    800038f4:	6ba2                	ld	s7,8(sp)
    800038f6:	6161                	addi	sp,sp,80
    800038f8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038fa:	04000613          	li	a2,64
    800038fe:	4581                	li	a1,0
    80003900:	854e                	mv	a0,s3
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	3d0080e7          	jalr	976(ra) # 80000cd2 <memset>
      dip->type = type;
    8000390a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000390e:	854a                	mv	a0,s2
    80003910:	00001097          	auipc	ra,0x1
    80003914:	c84080e7          	jalr	-892(ra) # 80004594 <log_write>
      brelse(bp);
    80003918:	854a                	mv	a0,s2
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	9f6080e7          	jalr	-1546(ra) # 80003310 <brelse>
      return iget(dev, inum);
    80003922:	85da                	mv	a1,s6
    80003924:	8556                	mv	a0,s5
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	d9c080e7          	jalr	-612(ra) # 800036c2 <iget>
    8000392e:	bf5d                	j	800038e4 <ialloc+0x86>

0000000080003930 <iupdate>:
{
    80003930:	1101                	addi	sp,sp,-32
    80003932:	ec06                	sd	ra,24(sp)
    80003934:	e822                	sd	s0,16(sp)
    80003936:	e426                	sd	s1,8(sp)
    80003938:	e04a                	sd	s2,0(sp)
    8000393a:	1000                	addi	s0,sp,32
    8000393c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000393e:	415c                	lw	a5,4(a0)
    80003940:	0047d79b          	srliw	a5,a5,0x4
    80003944:	0001c597          	auipc	a1,0x1c
    80003948:	32c5a583          	lw	a1,812(a1) # 8001fc70 <sb+0x18>
    8000394c:	9dbd                	addw	a1,a1,a5
    8000394e:	4108                	lw	a0,0(a0)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	890080e7          	jalr	-1904(ra) # 800031e0 <bread>
    80003958:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395a:	05850793          	addi	a5,a0,88
    8000395e:	40c8                	lw	a0,4(s1)
    80003960:	893d                	andi	a0,a0,15
    80003962:	051a                	slli	a0,a0,0x6
    80003964:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003966:	04449703          	lh	a4,68(s1)
    8000396a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000396e:	04649703          	lh	a4,70(s1)
    80003972:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003976:	04849703          	lh	a4,72(s1)
    8000397a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000397e:	04a49703          	lh	a4,74(s1)
    80003982:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003986:	44f8                	lw	a4,76(s1)
    80003988:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000398a:	03400613          	li	a2,52
    8000398e:	05048593          	addi	a1,s1,80
    80003992:	0531                	addi	a0,a0,12
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	39a080e7          	jalr	922(ra) # 80000d2e <memmove>
  log_write(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	bf6080e7          	jalr	-1034(ra) # 80004594 <log_write>
  brelse(bp);
    800039a6:	854a                	mv	a0,s2
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	968080e7          	jalr	-1688(ra) # 80003310 <brelse>
}
    800039b0:	60e2                	ld	ra,24(sp)
    800039b2:	6442                	ld	s0,16(sp)
    800039b4:	64a2                	ld	s1,8(sp)
    800039b6:	6902                	ld	s2,0(sp)
    800039b8:	6105                	addi	sp,sp,32
    800039ba:	8082                	ret

00000000800039bc <idup>:
{
    800039bc:	1101                	addi	sp,sp,-32
    800039be:	ec06                	sd	ra,24(sp)
    800039c0:	e822                	sd	s0,16(sp)
    800039c2:	e426                	sd	s1,8(sp)
    800039c4:	1000                	addi	s0,sp,32
    800039c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039c8:	0001c517          	auipc	a0,0x1c
    800039cc:	2b050513          	addi	a0,a0,688 # 8001fc78 <itable>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	206080e7          	jalr	518(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039d8:	449c                	lw	a5,8(s1)
    800039da:	2785                	addiw	a5,a5,1
    800039dc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039de:	0001c517          	auipc	a0,0x1c
    800039e2:	29a50513          	addi	a0,a0,666 # 8001fc78 <itable>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	2a4080e7          	jalr	676(ra) # 80000c8a <release>
}
    800039ee:	8526                	mv	a0,s1
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6105                	addi	sp,sp,32
    800039f8:	8082                	ret

00000000800039fa <ilock>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	e04a                	sd	s2,0(sp)
    80003a04:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a06:	c115                	beqz	a0,80003a2a <ilock+0x30>
    80003a08:	84aa                	mv	s1,a0
    80003a0a:	451c                	lw	a5,8(a0)
    80003a0c:	00f05f63          	blez	a5,80003a2a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a10:	0541                	addi	a0,a0,16
    80003a12:	00001097          	auipc	ra,0x1
    80003a16:	ca2080e7          	jalr	-862(ra) # 800046b4 <acquiresleep>
  if(ip->valid == 0){
    80003a1a:	40bc                	lw	a5,64(s1)
    80003a1c:	cf99                	beqz	a5,80003a3a <ilock+0x40>
}
    80003a1e:	60e2                	ld	ra,24(sp)
    80003a20:	6442                	ld	s0,16(sp)
    80003a22:	64a2                	ld	s1,8(sp)
    80003a24:	6902                	ld	s2,0(sp)
    80003a26:	6105                	addi	sp,sp,32
    80003a28:	8082                	ret
    panic("ilock");
    80003a2a:	00005517          	auipc	a0,0x5
    80003a2e:	bc650513          	addi	a0,a0,-1082 # 800085f0 <syscalls+0x1a0>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a3a:	40dc                	lw	a5,4(s1)
    80003a3c:	0047d79b          	srliw	a5,a5,0x4
    80003a40:	0001c597          	auipc	a1,0x1c
    80003a44:	2305a583          	lw	a1,560(a1) # 8001fc70 <sb+0x18>
    80003a48:	9dbd                	addw	a1,a1,a5
    80003a4a:	4088                	lw	a0,0(s1)
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	794080e7          	jalr	1940(ra) # 800031e0 <bread>
    80003a54:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a56:	05850593          	addi	a1,a0,88
    80003a5a:	40dc                	lw	a5,4(s1)
    80003a5c:	8bbd                	andi	a5,a5,15
    80003a5e:	079a                	slli	a5,a5,0x6
    80003a60:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a62:	00059783          	lh	a5,0(a1)
    80003a66:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a6a:	00259783          	lh	a5,2(a1)
    80003a6e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a72:	00459783          	lh	a5,4(a1)
    80003a76:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a7a:	00659783          	lh	a5,6(a1)
    80003a7e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a82:	459c                	lw	a5,8(a1)
    80003a84:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a86:	03400613          	li	a2,52
    80003a8a:	05b1                	addi	a1,a1,12
    80003a8c:	05048513          	addi	a0,s1,80
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	29e080e7          	jalr	670(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	876080e7          	jalr	-1930(ra) # 80003310 <brelse>
    ip->valid = 1;
    80003aa2:	4785                	li	a5,1
    80003aa4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aa6:	04449783          	lh	a5,68(s1)
    80003aaa:	fbb5                	bnez	a5,80003a1e <ilock+0x24>
      panic("ilock: no type");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	b4c50513          	addi	a0,a0,-1204 # 800085f8 <syscalls+0x1a8>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>

0000000080003abc <iunlock>:
{
    80003abc:	1101                	addi	sp,sp,-32
    80003abe:	ec06                	sd	ra,24(sp)
    80003ac0:	e822                	sd	s0,16(sp)
    80003ac2:	e426                	sd	s1,8(sp)
    80003ac4:	e04a                	sd	s2,0(sp)
    80003ac6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ac8:	c905                	beqz	a0,80003af8 <iunlock+0x3c>
    80003aca:	84aa                	mv	s1,a0
    80003acc:	01050913          	addi	s2,a0,16
    80003ad0:	854a                	mv	a0,s2
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	c7c080e7          	jalr	-900(ra) # 8000474e <holdingsleep>
    80003ada:	cd19                	beqz	a0,80003af8 <iunlock+0x3c>
    80003adc:	449c                	lw	a5,8(s1)
    80003ade:	00f05d63          	blez	a5,80003af8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	c26080e7          	jalr	-986(ra) # 8000470a <releasesleep>
}
    80003aec:	60e2                	ld	ra,24(sp)
    80003aee:	6442                	ld	s0,16(sp)
    80003af0:	64a2                	ld	s1,8(sp)
    80003af2:	6902                	ld	s2,0(sp)
    80003af4:	6105                	addi	sp,sp,32
    80003af6:	8082                	ret
    panic("iunlock");
    80003af8:	00005517          	auipc	a0,0x5
    80003afc:	b1050513          	addi	a0,a0,-1264 # 80008608 <syscalls+0x1b8>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>

0000000080003b08 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b08:	7179                	addi	sp,sp,-48
    80003b0a:	f406                	sd	ra,40(sp)
    80003b0c:	f022                	sd	s0,32(sp)
    80003b0e:	ec26                	sd	s1,24(sp)
    80003b10:	e84a                	sd	s2,16(sp)
    80003b12:	e44e                	sd	s3,8(sp)
    80003b14:	e052                	sd	s4,0(sp)
    80003b16:	1800                	addi	s0,sp,48
    80003b18:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b1a:	05050493          	addi	s1,a0,80
    80003b1e:	08050913          	addi	s2,a0,128
    80003b22:	a021                	j	80003b2a <itrunc+0x22>
    80003b24:	0491                	addi	s1,s1,4
    80003b26:	01248d63          	beq	s1,s2,80003b40 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b2a:	408c                	lw	a1,0(s1)
    80003b2c:	dde5                	beqz	a1,80003b24 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b2e:	0009a503          	lw	a0,0(s3)
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	8f4080e7          	jalr	-1804(ra) # 80003426 <bfree>
      ip->addrs[i] = 0;
    80003b3a:	0004a023          	sw	zero,0(s1)
    80003b3e:	b7dd                	j	80003b24 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b40:	0809a583          	lw	a1,128(s3)
    80003b44:	e185                	bnez	a1,80003b64 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b46:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b4a:	854e                	mv	a0,s3
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	de4080e7          	jalr	-540(ra) # 80003930 <iupdate>
}
    80003b54:	70a2                	ld	ra,40(sp)
    80003b56:	7402                	ld	s0,32(sp)
    80003b58:	64e2                	ld	s1,24(sp)
    80003b5a:	6942                	ld	s2,16(sp)
    80003b5c:	69a2                	ld	s3,8(sp)
    80003b5e:	6a02                	ld	s4,0(sp)
    80003b60:	6145                	addi	sp,sp,48
    80003b62:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b64:	0009a503          	lw	a0,0(s3)
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	678080e7          	jalr	1656(ra) # 800031e0 <bread>
    80003b70:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b72:	05850493          	addi	s1,a0,88
    80003b76:	45850913          	addi	s2,a0,1112
    80003b7a:	a021                	j	80003b82 <itrunc+0x7a>
    80003b7c:	0491                	addi	s1,s1,4
    80003b7e:	01248b63          	beq	s1,s2,80003b94 <itrunc+0x8c>
      if(a[j])
    80003b82:	408c                	lw	a1,0(s1)
    80003b84:	dde5                	beqz	a1,80003b7c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b86:	0009a503          	lw	a0,0(s3)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	89c080e7          	jalr	-1892(ra) # 80003426 <bfree>
    80003b92:	b7ed                	j	80003b7c <itrunc+0x74>
    brelse(bp);
    80003b94:	8552                	mv	a0,s4
    80003b96:	fffff097          	auipc	ra,0xfffff
    80003b9a:	77a080e7          	jalr	1914(ra) # 80003310 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b9e:	0809a583          	lw	a1,128(s3)
    80003ba2:	0009a503          	lw	a0,0(s3)
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	880080e7          	jalr	-1920(ra) # 80003426 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bae:	0809a023          	sw	zero,128(s3)
    80003bb2:	bf51                	j	80003b46 <itrunc+0x3e>

0000000080003bb4 <iput>:
{
    80003bb4:	1101                	addi	sp,sp,-32
    80003bb6:	ec06                	sd	ra,24(sp)
    80003bb8:	e822                	sd	s0,16(sp)
    80003bba:	e426                	sd	s1,8(sp)
    80003bbc:	e04a                	sd	s2,0(sp)
    80003bbe:	1000                	addi	s0,sp,32
    80003bc0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bc2:	0001c517          	auipc	a0,0x1c
    80003bc6:	0b650513          	addi	a0,a0,182 # 8001fc78 <itable>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	00c080e7          	jalr	12(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd2:	4498                	lw	a4,8(s1)
    80003bd4:	4785                	li	a5,1
    80003bd6:	02f70363          	beq	a4,a5,80003bfc <iput+0x48>
  ip->ref--;
    80003bda:	449c                	lw	a5,8(s1)
    80003bdc:	37fd                	addiw	a5,a5,-1
    80003bde:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003be0:	0001c517          	auipc	a0,0x1c
    80003be4:	09850513          	addi	a0,a0,152 # 8001fc78 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	0a2080e7          	jalr	162(ra) # 80000c8a <release>
}
    80003bf0:	60e2                	ld	ra,24(sp)
    80003bf2:	6442                	ld	s0,16(sp)
    80003bf4:	64a2                	ld	s1,8(sp)
    80003bf6:	6902                	ld	s2,0(sp)
    80003bf8:	6105                	addi	sp,sp,32
    80003bfa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bfc:	40bc                	lw	a5,64(s1)
    80003bfe:	dff1                	beqz	a5,80003bda <iput+0x26>
    80003c00:	04a49783          	lh	a5,74(s1)
    80003c04:	fbf9                	bnez	a5,80003bda <iput+0x26>
    acquiresleep(&ip->lock);
    80003c06:	01048913          	addi	s2,s1,16
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00001097          	auipc	ra,0x1
    80003c10:	aa8080e7          	jalr	-1368(ra) # 800046b4 <acquiresleep>
    release(&itable.lock);
    80003c14:	0001c517          	auipc	a0,0x1c
    80003c18:	06450513          	addi	a0,a0,100 # 8001fc78 <itable>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	06e080e7          	jalr	110(ra) # 80000c8a <release>
    itrunc(ip);
    80003c24:	8526                	mv	a0,s1
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	ee2080e7          	jalr	-286(ra) # 80003b08 <itrunc>
    ip->type = 0;
    80003c2e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c32:	8526                	mv	a0,s1
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	cfc080e7          	jalr	-772(ra) # 80003930 <iupdate>
    ip->valid = 0;
    80003c3c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c40:	854a                	mv	a0,s2
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	ac8080e7          	jalr	-1336(ra) # 8000470a <releasesleep>
    acquire(&itable.lock);
    80003c4a:	0001c517          	auipc	a0,0x1c
    80003c4e:	02e50513          	addi	a0,a0,46 # 8001fc78 <itable>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	f84080e7          	jalr	-124(ra) # 80000bd6 <acquire>
    80003c5a:	b741                	j	80003bda <iput+0x26>

0000000080003c5c <iunlockput>:
{
    80003c5c:	1101                	addi	sp,sp,-32
    80003c5e:	ec06                	sd	ra,24(sp)
    80003c60:	e822                	sd	s0,16(sp)
    80003c62:	e426                	sd	s1,8(sp)
    80003c64:	1000                	addi	s0,sp,32
    80003c66:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	e54080e7          	jalr	-428(ra) # 80003abc <iunlock>
  iput(ip);
    80003c70:	8526                	mv	a0,s1
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	f42080e7          	jalr	-190(ra) # 80003bb4 <iput>
}
    80003c7a:	60e2                	ld	ra,24(sp)
    80003c7c:	6442                	ld	s0,16(sp)
    80003c7e:	64a2                	ld	s1,8(sp)
    80003c80:	6105                	addi	sp,sp,32
    80003c82:	8082                	ret

0000000080003c84 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c84:	1141                	addi	sp,sp,-16
    80003c86:	e422                	sd	s0,8(sp)
    80003c88:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c8a:	411c                	lw	a5,0(a0)
    80003c8c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c8e:	415c                	lw	a5,4(a0)
    80003c90:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c92:	04451783          	lh	a5,68(a0)
    80003c96:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c9a:	04a51783          	lh	a5,74(a0)
    80003c9e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ca2:	04c56783          	lwu	a5,76(a0)
    80003ca6:	e99c                	sd	a5,16(a1)
}
    80003ca8:	6422                	ld	s0,8(sp)
    80003caa:	0141                	addi	sp,sp,16
    80003cac:	8082                	ret

0000000080003cae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cae:	457c                	lw	a5,76(a0)
    80003cb0:	0ed7e963          	bltu	a5,a3,80003da2 <readi+0xf4>
{
    80003cb4:	7159                	addi	sp,sp,-112
    80003cb6:	f486                	sd	ra,104(sp)
    80003cb8:	f0a2                	sd	s0,96(sp)
    80003cba:	eca6                	sd	s1,88(sp)
    80003cbc:	e8ca                	sd	s2,80(sp)
    80003cbe:	e4ce                	sd	s3,72(sp)
    80003cc0:	e0d2                	sd	s4,64(sp)
    80003cc2:	fc56                	sd	s5,56(sp)
    80003cc4:	f85a                	sd	s6,48(sp)
    80003cc6:	f45e                	sd	s7,40(sp)
    80003cc8:	f062                	sd	s8,32(sp)
    80003cca:	ec66                	sd	s9,24(sp)
    80003ccc:	e86a                	sd	s10,16(sp)
    80003cce:	e46e                	sd	s11,8(sp)
    80003cd0:	1880                	addi	s0,sp,112
    80003cd2:	8b2a                	mv	s6,a0
    80003cd4:	8bae                	mv	s7,a1
    80003cd6:	8a32                	mv	s4,a2
    80003cd8:	84b6                	mv	s1,a3
    80003cda:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cdc:	9f35                	addw	a4,a4,a3
    return 0;
    80003cde:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ce0:	0ad76063          	bltu	a4,a3,80003d80 <readi+0xd2>
  if(off + n > ip->size)
    80003ce4:	00e7f463          	bgeu	a5,a4,80003cec <readi+0x3e>
    n = ip->size - off;
    80003ce8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cec:	0a0a8963          	beqz	s5,80003d9e <readi+0xf0>
    80003cf0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cf6:	5c7d                	li	s8,-1
    80003cf8:	a82d                	j	80003d32 <readi+0x84>
    80003cfa:	020d1d93          	slli	s11,s10,0x20
    80003cfe:	020ddd93          	srli	s11,s11,0x20
    80003d02:	05890793          	addi	a5,s2,88
    80003d06:	86ee                	mv	a3,s11
    80003d08:	963e                	add	a2,a2,a5
    80003d0a:	85d2                	mv	a1,s4
    80003d0c:	855e                	mv	a0,s7
    80003d0e:	ffffe097          	auipc	ra,0xffffe
    80003d12:	782080e7          	jalr	1922(ra) # 80002490 <either_copyout>
    80003d16:	05850d63          	beq	a0,s8,80003d70 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	5f4080e7          	jalr	1524(ra) # 80003310 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d24:	013d09bb          	addw	s3,s10,s3
    80003d28:	009d04bb          	addw	s1,s10,s1
    80003d2c:	9a6e                	add	s4,s4,s11
    80003d2e:	0559f763          	bgeu	s3,s5,80003d7c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d32:	00a4d59b          	srliw	a1,s1,0xa
    80003d36:	855a                	mv	a0,s6
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	8a2080e7          	jalr	-1886(ra) # 800035da <bmap>
    80003d40:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d44:	cd85                	beqz	a1,80003d7c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d46:	000b2503          	lw	a0,0(s6)
    80003d4a:	fffff097          	auipc	ra,0xfffff
    80003d4e:	496080e7          	jalr	1174(ra) # 800031e0 <bread>
    80003d52:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d54:	3ff4f613          	andi	a2,s1,1023
    80003d58:	40cc87bb          	subw	a5,s9,a2
    80003d5c:	413a873b          	subw	a4,s5,s3
    80003d60:	8d3e                	mv	s10,a5
    80003d62:	2781                	sext.w	a5,a5
    80003d64:	0007069b          	sext.w	a3,a4
    80003d68:	f8f6f9e3          	bgeu	a3,a5,80003cfa <readi+0x4c>
    80003d6c:	8d3a                	mv	s10,a4
    80003d6e:	b771                	j	80003cfa <readi+0x4c>
      brelse(bp);
    80003d70:	854a                	mv	a0,s2
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	59e080e7          	jalr	1438(ra) # 80003310 <brelse>
      tot = -1;
    80003d7a:	59fd                	li	s3,-1
  }
  return tot;
    80003d7c:	0009851b          	sext.w	a0,s3
}
    80003d80:	70a6                	ld	ra,104(sp)
    80003d82:	7406                	ld	s0,96(sp)
    80003d84:	64e6                	ld	s1,88(sp)
    80003d86:	6946                	ld	s2,80(sp)
    80003d88:	69a6                	ld	s3,72(sp)
    80003d8a:	6a06                	ld	s4,64(sp)
    80003d8c:	7ae2                	ld	s5,56(sp)
    80003d8e:	7b42                	ld	s6,48(sp)
    80003d90:	7ba2                	ld	s7,40(sp)
    80003d92:	7c02                	ld	s8,32(sp)
    80003d94:	6ce2                	ld	s9,24(sp)
    80003d96:	6d42                	ld	s10,16(sp)
    80003d98:	6da2                	ld	s11,8(sp)
    80003d9a:	6165                	addi	sp,sp,112
    80003d9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d9e:	89d6                	mv	s3,s5
    80003da0:	bff1                	j	80003d7c <readi+0xce>
    return 0;
    80003da2:	4501                	li	a0,0
}
    80003da4:	8082                	ret

0000000080003da6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003da6:	457c                	lw	a5,76(a0)
    80003da8:	10d7e863          	bltu	a5,a3,80003eb8 <writei+0x112>
{
    80003dac:	7159                	addi	sp,sp,-112
    80003dae:	f486                	sd	ra,104(sp)
    80003db0:	f0a2                	sd	s0,96(sp)
    80003db2:	eca6                	sd	s1,88(sp)
    80003db4:	e8ca                	sd	s2,80(sp)
    80003db6:	e4ce                	sd	s3,72(sp)
    80003db8:	e0d2                	sd	s4,64(sp)
    80003dba:	fc56                	sd	s5,56(sp)
    80003dbc:	f85a                	sd	s6,48(sp)
    80003dbe:	f45e                	sd	s7,40(sp)
    80003dc0:	f062                	sd	s8,32(sp)
    80003dc2:	ec66                	sd	s9,24(sp)
    80003dc4:	e86a                	sd	s10,16(sp)
    80003dc6:	e46e                	sd	s11,8(sp)
    80003dc8:	1880                	addi	s0,sp,112
    80003dca:	8aaa                	mv	s5,a0
    80003dcc:	8bae                	mv	s7,a1
    80003dce:	8a32                	mv	s4,a2
    80003dd0:	8936                	mv	s2,a3
    80003dd2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dd4:	00e687bb          	addw	a5,a3,a4
    80003dd8:	0ed7e263          	bltu	a5,a3,80003ebc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ddc:	00043737          	lui	a4,0x43
    80003de0:	0ef76063          	bltu	a4,a5,80003ec0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de4:	0c0b0863          	beqz	s6,80003eb4 <writei+0x10e>
    80003de8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dea:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dee:	5c7d                	li	s8,-1
    80003df0:	a091                	j	80003e34 <writei+0x8e>
    80003df2:	020d1d93          	slli	s11,s10,0x20
    80003df6:	020ddd93          	srli	s11,s11,0x20
    80003dfa:	05848793          	addi	a5,s1,88
    80003dfe:	86ee                	mv	a3,s11
    80003e00:	8652                	mv	a2,s4
    80003e02:	85de                	mv	a1,s7
    80003e04:	953e                	add	a0,a0,a5
    80003e06:	ffffe097          	auipc	ra,0xffffe
    80003e0a:	6e0080e7          	jalr	1760(ra) # 800024e6 <either_copyin>
    80003e0e:	07850263          	beq	a0,s8,80003e72 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e12:	8526                	mv	a0,s1
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	780080e7          	jalr	1920(ra) # 80004594 <log_write>
    brelse(bp);
    80003e1c:	8526                	mv	a0,s1
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	4f2080e7          	jalr	1266(ra) # 80003310 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e26:	013d09bb          	addw	s3,s10,s3
    80003e2a:	012d093b          	addw	s2,s10,s2
    80003e2e:	9a6e                	add	s4,s4,s11
    80003e30:	0569f663          	bgeu	s3,s6,80003e7c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e34:	00a9559b          	srliw	a1,s2,0xa
    80003e38:	8556                	mv	a0,s5
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	7a0080e7          	jalr	1952(ra) # 800035da <bmap>
    80003e42:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e46:	c99d                	beqz	a1,80003e7c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e48:	000aa503          	lw	a0,0(s5)
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	394080e7          	jalr	916(ra) # 800031e0 <bread>
    80003e54:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e56:	3ff97513          	andi	a0,s2,1023
    80003e5a:	40ac87bb          	subw	a5,s9,a0
    80003e5e:	413b073b          	subw	a4,s6,s3
    80003e62:	8d3e                	mv	s10,a5
    80003e64:	2781                	sext.w	a5,a5
    80003e66:	0007069b          	sext.w	a3,a4
    80003e6a:	f8f6f4e3          	bgeu	a3,a5,80003df2 <writei+0x4c>
    80003e6e:	8d3a                	mv	s10,a4
    80003e70:	b749                	j	80003df2 <writei+0x4c>
      brelse(bp);
    80003e72:	8526                	mv	a0,s1
    80003e74:	fffff097          	auipc	ra,0xfffff
    80003e78:	49c080e7          	jalr	1180(ra) # 80003310 <brelse>
  }

  if(off > ip->size)
    80003e7c:	04caa783          	lw	a5,76(s5)
    80003e80:	0127f463          	bgeu	a5,s2,80003e88 <writei+0xe2>
    ip->size = off;
    80003e84:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e88:	8556                	mv	a0,s5
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	aa6080e7          	jalr	-1370(ra) # 80003930 <iupdate>

  return tot;
    80003e92:	0009851b          	sext.w	a0,s3
}
    80003e96:	70a6                	ld	ra,104(sp)
    80003e98:	7406                	ld	s0,96(sp)
    80003e9a:	64e6                	ld	s1,88(sp)
    80003e9c:	6946                	ld	s2,80(sp)
    80003e9e:	69a6                	ld	s3,72(sp)
    80003ea0:	6a06                	ld	s4,64(sp)
    80003ea2:	7ae2                	ld	s5,56(sp)
    80003ea4:	7b42                	ld	s6,48(sp)
    80003ea6:	7ba2                	ld	s7,40(sp)
    80003ea8:	7c02                	ld	s8,32(sp)
    80003eaa:	6ce2                	ld	s9,24(sp)
    80003eac:	6d42                	ld	s10,16(sp)
    80003eae:	6da2                	ld	s11,8(sp)
    80003eb0:	6165                	addi	sp,sp,112
    80003eb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eb4:	89da                	mv	s3,s6
    80003eb6:	bfc9                	j	80003e88 <writei+0xe2>
    return -1;
    80003eb8:	557d                	li	a0,-1
}
    80003eba:	8082                	ret
    return -1;
    80003ebc:	557d                	li	a0,-1
    80003ebe:	bfe1                	j	80003e96 <writei+0xf0>
    return -1;
    80003ec0:	557d                	li	a0,-1
    80003ec2:	bfd1                	j	80003e96 <writei+0xf0>

0000000080003ec4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ec4:	1141                	addi	sp,sp,-16
    80003ec6:	e406                	sd	ra,8(sp)
    80003ec8:	e022                	sd	s0,0(sp)
    80003eca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ecc:	4639                	li	a2,14
    80003ece:	ffffd097          	auipc	ra,0xffffd
    80003ed2:	ed4080e7          	jalr	-300(ra) # 80000da2 <strncmp>
}
    80003ed6:	60a2                	ld	ra,8(sp)
    80003ed8:	6402                	ld	s0,0(sp)
    80003eda:	0141                	addi	sp,sp,16
    80003edc:	8082                	ret

0000000080003ede <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ede:	7139                	addi	sp,sp,-64
    80003ee0:	fc06                	sd	ra,56(sp)
    80003ee2:	f822                	sd	s0,48(sp)
    80003ee4:	f426                	sd	s1,40(sp)
    80003ee6:	f04a                	sd	s2,32(sp)
    80003ee8:	ec4e                	sd	s3,24(sp)
    80003eea:	e852                	sd	s4,16(sp)
    80003eec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eee:	04451703          	lh	a4,68(a0)
    80003ef2:	4785                	li	a5,1
    80003ef4:	00f71a63          	bne	a4,a5,80003f08 <dirlookup+0x2a>
    80003ef8:	892a                	mv	s2,a0
    80003efa:	89ae                	mv	s3,a1
    80003efc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efe:	457c                	lw	a5,76(a0)
    80003f00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f04:	e79d                	bnez	a5,80003f32 <dirlookup+0x54>
    80003f06:	a8a5                	j	80003f7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f08:	00004517          	auipc	a0,0x4
    80003f0c:	70850513          	addi	a0,a0,1800 # 80008610 <syscalls+0x1c0>
    80003f10:	ffffc097          	auipc	ra,0xffffc
    80003f14:	62e080e7          	jalr	1582(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f18:	00004517          	auipc	a0,0x4
    80003f1c:	71050513          	addi	a0,a0,1808 # 80008628 <syscalls+0x1d8>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	61e080e7          	jalr	1566(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f28:	24c1                	addiw	s1,s1,16
    80003f2a:	04c92783          	lw	a5,76(s2)
    80003f2e:	04f4f763          	bgeu	s1,a5,80003f7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f32:	4741                	li	a4,16
    80003f34:	86a6                	mv	a3,s1
    80003f36:	fc040613          	addi	a2,s0,-64
    80003f3a:	4581                	li	a1,0
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	d70080e7          	jalr	-656(ra) # 80003cae <readi>
    80003f46:	47c1                	li	a5,16
    80003f48:	fcf518e3          	bne	a0,a5,80003f18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f4c:	fc045783          	lhu	a5,-64(s0)
    80003f50:	dfe1                	beqz	a5,80003f28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f52:	fc240593          	addi	a1,s0,-62
    80003f56:	854e                	mv	a0,s3
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	f6c080e7          	jalr	-148(ra) # 80003ec4 <namecmp>
    80003f60:	f561                	bnez	a0,80003f28 <dirlookup+0x4a>
      if(poff)
    80003f62:	000a0463          	beqz	s4,80003f6a <dirlookup+0x8c>
        *poff = off;
    80003f66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f6a:	fc045583          	lhu	a1,-64(s0)
    80003f6e:	00092503          	lw	a0,0(s2)
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	750080e7          	jalr	1872(ra) # 800036c2 <iget>
    80003f7a:	a011                	j	80003f7e <dirlookup+0xa0>
  return 0;
    80003f7c:	4501                	li	a0,0
}
    80003f7e:	70e2                	ld	ra,56(sp)
    80003f80:	7442                	ld	s0,48(sp)
    80003f82:	74a2                	ld	s1,40(sp)
    80003f84:	7902                	ld	s2,32(sp)
    80003f86:	69e2                	ld	s3,24(sp)
    80003f88:	6a42                	ld	s4,16(sp)
    80003f8a:	6121                	addi	sp,sp,64
    80003f8c:	8082                	ret

0000000080003f8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f8e:	711d                	addi	sp,sp,-96
    80003f90:	ec86                	sd	ra,88(sp)
    80003f92:	e8a2                	sd	s0,80(sp)
    80003f94:	e4a6                	sd	s1,72(sp)
    80003f96:	e0ca                	sd	s2,64(sp)
    80003f98:	fc4e                	sd	s3,56(sp)
    80003f9a:	f852                	sd	s4,48(sp)
    80003f9c:	f456                	sd	s5,40(sp)
    80003f9e:	f05a                	sd	s6,32(sp)
    80003fa0:	ec5e                	sd	s7,24(sp)
    80003fa2:	e862                	sd	s8,16(sp)
    80003fa4:	e466                	sd	s9,8(sp)
    80003fa6:	1080                	addi	s0,sp,96
    80003fa8:	84aa                	mv	s1,a0
    80003faa:	8aae                	mv	s5,a1
    80003fac:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fae:	00054703          	lbu	a4,0(a0)
    80003fb2:	02f00793          	li	a5,47
    80003fb6:	02f70363          	beq	a4,a5,80003fdc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fba:	ffffe097          	auipc	ra,0xffffe
    80003fbe:	9f2080e7          	jalr	-1550(ra) # 800019ac <myproc>
    80003fc2:	17053503          	ld	a0,368(a0)
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	9f6080e7          	jalr	-1546(ra) # 800039bc <idup>
    80003fce:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fd0:	02f00913          	li	s2,47
  len = path - s;
    80003fd4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fd6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fd8:	4b85                	li	s7,1
    80003fda:	a865                	j	80004092 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fdc:	4585                	li	a1,1
    80003fde:	4505                	li	a0,1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	6e2080e7          	jalr	1762(ra) # 800036c2 <iget>
    80003fe8:	89aa                	mv	s3,a0
    80003fea:	b7dd                	j	80003fd0 <namex+0x42>
      iunlockput(ip);
    80003fec:	854e                	mv	a0,s3
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	c6e080e7          	jalr	-914(ra) # 80003c5c <iunlockput>
      return 0;
    80003ff6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ff8:	854e                	mv	a0,s3
    80003ffa:	60e6                	ld	ra,88(sp)
    80003ffc:	6446                	ld	s0,80(sp)
    80003ffe:	64a6                	ld	s1,72(sp)
    80004000:	6906                	ld	s2,64(sp)
    80004002:	79e2                	ld	s3,56(sp)
    80004004:	7a42                	ld	s4,48(sp)
    80004006:	7aa2                	ld	s5,40(sp)
    80004008:	7b02                	ld	s6,32(sp)
    8000400a:	6be2                	ld	s7,24(sp)
    8000400c:	6c42                	ld	s8,16(sp)
    8000400e:	6ca2                	ld	s9,8(sp)
    80004010:	6125                	addi	sp,sp,96
    80004012:	8082                	ret
      iunlock(ip);
    80004014:	854e                	mv	a0,s3
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	aa6080e7          	jalr	-1370(ra) # 80003abc <iunlock>
      return ip;
    8000401e:	bfe9                	j	80003ff8 <namex+0x6a>
      iunlockput(ip);
    80004020:	854e                	mv	a0,s3
    80004022:	00000097          	auipc	ra,0x0
    80004026:	c3a080e7          	jalr	-966(ra) # 80003c5c <iunlockput>
      return 0;
    8000402a:	89e6                	mv	s3,s9
    8000402c:	b7f1                	j	80003ff8 <namex+0x6a>
  len = path - s;
    8000402e:	40b48633          	sub	a2,s1,a1
    80004032:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004036:	099c5463          	bge	s8,s9,800040be <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000403a:	4639                	li	a2,14
    8000403c:	8552                	mv	a0,s4
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	cf0080e7          	jalr	-784(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004046:	0004c783          	lbu	a5,0(s1)
    8000404a:	01279763          	bne	a5,s2,80004058 <namex+0xca>
    path++;
    8000404e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	ff278de3          	beq	a5,s2,8000404e <namex+0xc0>
    ilock(ip);
    80004058:	854e                	mv	a0,s3
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	9a0080e7          	jalr	-1632(ra) # 800039fa <ilock>
    if(ip->type != T_DIR){
    80004062:	04499783          	lh	a5,68(s3)
    80004066:	f97793e3          	bne	a5,s7,80003fec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000406a:	000a8563          	beqz	s5,80004074 <namex+0xe6>
    8000406e:	0004c783          	lbu	a5,0(s1)
    80004072:	d3cd                	beqz	a5,80004014 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004074:	865a                	mv	a2,s6
    80004076:	85d2                	mv	a1,s4
    80004078:	854e                	mv	a0,s3
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	e64080e7          	jalr	-412(ra) # 80003ede <dirlookup>
    80004082:	8caa                	mv	s9,a0
    80004084:	dd51                	beqz	a0,80004020 <namex+0x92>
    iunlockput(ip);
    80004086:	854e                	mv	a0,s3
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	bd4080e7          	jalr	-1068(ra) # 80003c5c <iunlockput>
    ip = next;
    80004090:	89e6                	mv	s3,s9
  while(*path == '/')
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	05279763          	bne	a5,s2,800040e4 <namex+0x156>
    path++;
    8000409a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000409c:	0004c783          	lbu	a5,0(s1)
    800040a0:	ff278de3          	beq	a5,s2,8000409a <namex+0x10c>
  if(*path == 0)
    800040a4:	c79d                	beqz	a5,800040d2 <namex+0x144>
    path++;
    800040a6:	85a6                	mv	a1,s1
  len = path - s;
    800040a8:	8cda                	mv	s9,s6
    800040aa:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040ac:	01278963          	beq	a5,s2,800040be <namex+0x130>
    800040b0:	dfbd                	beqz	a5,8000402e <namex+0xa0>
    path++;
    800040b2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040b4:	0004c783          	lbu	a5,0(s1)
    800040b8:	ff279ce3          	bne	a5,s2,800040b0 <namex+0x122>
    800040bc:	bf8d                	j	8000402e <namex+0xa0>
    memmove(name, s, len);
    800040be:	2601                	sext.w	a2,a2
    800040c0:	8552                	mv	a0,s4
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	c6c080e7          	jalr	-916(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040ca:	9cd2                	add	s9,s9,s4
    800040cc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040d0:	bf9d                	j	80004046 <namex+0xb8>
  if(nameiparent){
    800040d2:	f20a83e3          	beqz	s5,80003ff8 <namex+0x6a>
    iput(ip);
    800040d6:	854e                	mv	a0,s3
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	adc080e7          	jalr	-1316(ra) # 80003bb4 <iput>
    return 0;
    800040e0:	4981                	li	s3,0
    800040e2:	bf19                	j	80003ff8 <namex+0x6a>
  if(*path == 0)
    800040e4:	d7fd                	beqz	a5,800040d2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040e6:	0004c783          	lbu	a5,0(s1)
    800040ea:	85a6                	mv	a1,s1
    800040ec:	b7d1                	j	800040b0 <namex+0x122>

00000000800040ee <dirlink>:
{
    800040ee:	7139                	addi	sp,sp,-64
    800040f0:	fc06                	sd	ra,56(sp)
    800040f2:	f822                	sd	s0,48(sp)
    800040f4:	f426                	sd	s1,40(sp)
    800040f6:	f04a                	sd	s2,32(sp)
    800040f8:	ec4e                	sd	s3,24(sp)
    800040fa:	e852                	sd	s4,16(sp)
    800040fc:	0080                	addi	s0,sp,64
    800040fe:	892a                	mv	s2,a0
    80004100:	8a2e                	mv	s4,a1
    80004102:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004104:	4601                	li	a2,0
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	dd8080e7          	jalr	-552(ra) # 80003ede <dirlookup>
    8000410e:	e93d                	bnez	a0,80004184 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004110:	04c92483          	lw	s1,76(s2)
    80004114:	c49d                	beqz	s1,80004142 <dirlink+0x54>
    80004116:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004118:	4741                	li	a4,16
    8000411a:	86a6                	mv	a3,s1
    8000411c:	fc040613          	addi	a2,s0,-64
    80004120:	4581                	li	a1,0
    80004122:	854a                	mv	a0,s2
    80004124:	00000097          	auipc	ra,0x0
    80004128:	b8a080e7          	jalr	-1142(ra) # 80003cae <readi>
    8000412c:	47c1                	li	a5,16
    8000412e:	06f51163          	bne	a0,a5,80004190 <dirlink+0xa2>
    if(de.inum == 0)
    80004132:	fc045783          	lhu	a5,-64(s0)
    80004136:	c791                	beqz	a5,80004142 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004138:	24c1                	addiw	s1,s1,16
    8000413a:	04c92783          	lw	a5,76(s2)
    8000413e:	fcf4ede3          	bltu	s1,a5,80004118 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004142:	4639                	li	a2,14
    80004144:	85d2                	mv	a1,s4
    80004146:	fc240513          	addi	a0,s0,-62
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	c94080e7          	jalr	-876(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004152:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004156:	4741                	li	a4,16
    80004158:	86a6                	mv	a3,s1
    8000415a:	fc040613          	addi	a2,s0,-64
    8000415e:	4581                	li	a1,0
    80004160:	854a                	mv	a0,s2
    80004162:	00000097          	auipc	ra,0x0
    80004166:	c44080e7          	jalr	-956(ra) # 80003da6 <writei>
    8000416a:	1541                	addi	a0,a0,-16
    8000416c:	00a03533          	snez	a0,a0
    80004170:	40a00533          	neg	a0,a0
}
    80004174:	70e2                	ld	ra,56(sp)
    80004176:	7442                	ld	s0,48(sp)
    80004178:	74a2                	ld	s1,40(sp)
    8000417a:	7902                	ld	s2,32(sp)
    8000417c:	69e2                	ld	s3,24(sp)
    8000417e:	6a42                	ld	s4,16(sp)
    80004180:	6121                	addi	sp,sp,64
    80004182:	8082                	ret
    iput(ip);
    80004184:	00000097          	auipc	ra,0x0
    80004188:	a30080e7          	jalr	-1488(ra) # 80003bb4 <iput>
    return -1;
    8000418c:	557d                	li	a0,-1
    8000418e:	b7dd                	j	80004174 <dirlink+0x86>
      panic("dirlink read");
    80004190:	00004517          	auipc	a0,0x4
    80004194:	4a850513          	addi	a0,a0,1192 # 80008638 <syscalls+0x1e8>
    80004198:	ffffc097          	auipc	ra,0xffffc
    8000419c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>

00000000800041a0 <namei>:

struct inode*
namei(char *path)
{
    800041a0:	1101                	addi	sp,sp,-32
    800041a2:	ec06                	sd	ra,24(sp)
    800041a4:	e822                	sd	s0,16(sp)
    800041a6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041a8:	fe040613          	addi	a2,s0,-32
    800041ac:	4581                	li	a1,0
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	de0080e7          	jalr	-544(ra) # 80003f8e <namex>
}
    800041b6:	60e2                	ld	ra,24(sp)
    800041b8:	6442                	ld	s0,16(sp)
    800041ba:	6105                	addi	sp,sp,32
    800041bc:	8082                	ret

00000000800041be <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041be:	1141                	addi	sp,sp,-16
    800041c0:	e406                	sd	ra,8(sp)
    800041c2:	e022                	sd	s0,0(sp)
    800041c4:	0800                	addi	s0,sp,16
    800041c6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041c8:	4585                	li	a1,1
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	dc4080e7          	jalr	-572(ra) # 80003f8e <namex>
}
    800041d2:	60a2                	ld	ra,8(sp)
    800041d4:	6402                	ld	s0,0(sp)
    800041d6:	0141                	addi	sp,sp,16
    800041d8:	8082                	ret

00000000800041da <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041da:	1101                	addi	sp,sp,-32
    800041dc:	ec06                	sd	ra,24(sp)
    800041de:	e822                	sd	s0,16(sp)
    800041e0:	e426                	sd	s1,8(sp)
    800041e2:	e04a                	sd	s2,0(sp)
    800041e4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041e6:	0001d917          	auipc	s2,0x1d
    800041ea:	53a90913          	addi	s2,s2,1338 # 80021720 <log>
    800041ee:	01892583          	lw	a1,24(s2)
    800041f2:	02892503          	lw	a0,40(s2)
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	fea080e7          	jalr	-22(ra) # 800031e0 <bread>
    800041fe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004200:	02c92683          	lw	a3,44(s2)
    80004204:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004206:	02d05763          	blez	a3,80004234 <write_head+0x5a>
    8000420a:	0001d797          	auipc	a5,0x1d
    8000420e:	54678793          	addi	a5,a5,1350 # 80021750 <log+0x30>
    80004212:	05c50713          	addi	a4,a0,92
    80004216:	36fd                	addiw	a3,a3,-1
    80004218:	1682                	slli	a3,a3,0x20
    8000421a:	9281                	srli	a3,a3,0x20
    8000421c:	068a                	slli	a3,a3,0x2
    8000421e:	0001d617          	auipc	a2,0x1d
    80004222:	53660613          	addi	a2,a2,1334 # 80021754 <log+0x34>
    80004226:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004228:	4390                	lw	a2,0(a5)
    8000422a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000422c:	0791                	addi	a5,a5,4
    8000422e:	0711                	addi	a4,a4,4
    80004230:	fed79ce3          	bne	a5,a3,80004228 <write_head+0x4e>
  }
  bwrite(buf);
    80004234:	8526                	mv	a0,s1
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	09c080e7          	jalr	156(ra) # 800032d2 <bwrite>
  brelse(buf);
    8000423e:	8526                	mv	a0,s1
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	0d0080e7          	jalr	208(ra) # 80003310 <brelse>
}
    80004248:	60e2                	ld	ra,24(sp)
    8000424a:	6442                	ld	s0,16(sp)
    8000424c:	64a2                	ld	s1,8(sp)
    8000424e:	6902                	ld	s2,0(sp)
    80004250:	6105                	addi	sp,sp,32
    80004252:	8082                	ret

0000000080004254 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004254:	0001d797          	auipc	a5,0x1d
    80004258:	4f87a783          	lw	a5,1272(a5) # 8002174c <log+0x2c>
    8000425c:	0af05d63          	blez	a5,80004316 <install_trans+0xc2>
{
    80004260:	7139                	addi	sp,sp,-64
    80004262:	fc06                	sd	ra,56(sp)
    80004264:	f822                	sd	s0,48(sp)
    80004266:	f426                	sd	s1,40(sp)
    80004268:	f04a                	sd	s2,32(sp)
    8000426a:	ec4e                	sd	s3,24(sp)
    8000426c:	e852                	sd	s4,16(sp)
    8000426e:	e456                	sd	s5,8(sp)
    80004270:	e05a                	sd	s6,0(sp)
    80004272:	0080                	addi	s0,sp,64
    80004274:	8b2a                	mv	s6,a0
    80004276:	0001da97          	auipc	s5,0x1d
    8000427a:	4daa8a93          	addi	s5,s5,1242 # 80021750 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004280:	0001d997          	auipc	s3,0x1d
    80004284:	4a098993          	addi	s3,s3,1184 # 80021720 <log>
    80004288:	a00d                	j	800042aa <install_trans+0x56>
    brelse(lbuf);
    8000428a:	854a                	mv	a0,s2
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	084080e7          	jalr	132(ra) # 80003310 <brelse>
    brelse(dbuf);
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	07a080e7          	jalr	122(ra) # 80003310 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429e:	2a05                	addiw	s4,s4,1
    800042a0:	0a91                	addi	s5,s5,4
    800042a2:	02c9a783          	lw	a5,44(s3)
    800042a6:	04fa5e63          	bge	s4,a5,80004302 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042aa:	0189a583          	lw	a1,24(s3)
    800042ae:	014585bb          	addw	a1,a1,s4
    800042b2:	2585                	addiw	a1,a1,1
    800042b4:	0289a503          	lw	a0,40(s3)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	f28080e7          	jalr	-216(ra) # 800031e0 <bread>
    800042c0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042c2:	000aa583          	lw	a1,0(s5)
    800042c6:	0289a503          	lw	a0,40(s3)
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	f16080e7          	jalr	-234(ra) # 800031e0 <bread>
    800042d2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042d4:	40000613          	li	a2,1024
    800042d8:	05890593          	addi	a1,s2,88
    800042dc:	05850513          	addi	a0,a0,88
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	a4e080e7          	jalr	-1458(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042e8:	8526                	mv	a0,s1
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	fe8080e7          	jalr	-24(ra) # 800032d2 <bwrite>
    if(recovering == 0)
    800042f2:	f80b1ce3          	bnez	s6,8000428a <install_trans+0x36>
      bunpin(dbuf);
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	0f2080e7          	jalr	242(ra) # 800033ea <bunpin>
    80004300:	b769                	j	8000428a <install_trans+0x36>
}
    80004302:	70e2                	ld	ra,56(sp)
    80004304:	7442                	ld	s0,48(sp)
    80004306:	74a2                	ld	s1,40(sp)
    80004308:	7902                	ld	s2,32(sp)
    8000430a:	69e2                	ld	s3,24(sp)
    8000430c:	6a42                	ld	s4,16(sp)
    8000430e:	6aa2                	ld	s5,8(sp)
    80004310:	6b02                	ld	s6,0(sp)
    80004312:	6121                	addi	sp,sp,64
    80004314:	8082                	ret
    80004316:	8082                	ret

0000000080004318 <initlog>:
{
    80004318:	7179                	addi	sp,sp,-48
    8000431a:	f406                	sd	ra,40(sp)
    8000431c:	f022                	sd	s0,32(sp)
    8000431e:	ec26                	sd	s1,24(sp)
    80004320:	e84a                	sd	s2,16(sp)
    80004322:	e44e                	sd	s3,8(sp)
    80004324:	1800                	addi	s0,sp,48
    80004326:	892a                	mv	s2,a0
    80004328:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000432a:	0001d497          	auipc	s1,0x1d
    8000432e:	3f648493          	addi	s1,s1,1014 # 80021720 <log>
    80004332:	00004597          	auipc	a1,0x4
    80004336:	31658593          	addi	a1,a1,790 # 80008648 <syscalls+0x1f8>
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	80a080e7          	jalr	-2038(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004344:	0149a583          	lw	a1,20(s3)
    80004348:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000434a:	0109a783          	lw	a5,16(s3)
    8000434e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004350:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004354:	854a                	mv	a0,s2
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	e8a080e7          	jalr	-374(ra) # 800031e0 <bread>
  log.lh.n = lh->n;
    8000435e:	4d34                	lw	a3,88(a0)
    80004360:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004362:	02d05563          	blez	a3,8000438c <initlog+0x74>
    80004366:	05c50793          	addi	a5,a0,92
    8000436a:	0001d717          	auipc	a4,0x1d
    8000436e:	3e670713          	addi	a4,a4,998 # 80021750 <log+0x30>
    80004372:	36fd                	addiw	a3,a3,-1
    80004374:	1682                	slli	a3,a3,0x20
    80004376:	9281                	srli	a3,a3,0x20
    80004378:	068a                	slli	a3,a3,0x2
    8000437a:	06050613          	addi	a2,a0,96
    8000437e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004380:	4390                	lw	a2,0(a5)
    80004382:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004384:	0791                	addi	a5,a5,4
    80004386:	0711                	addi	a4,a4,4
    80004388:	fed79ce3          	bne	a5,a3,80004380 <initlog+0x68>
  brelse(buf);
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	f84080e7          	jalr	-124(ra) # 80003310 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004394:	4505                	li	a0,1
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	ebe080e7          	jalr	-322(ra) # 80004254 <install_trans>
  log.lh.n = 0;
    8000439e:	0001d797          	auipc	a5,0x1d
    800043a2:	3a07a723          	sw	zero,942(a5) # 8002174c <log+0x2c>
  write_head(); // clear the log
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	e34080e7          	jalr	-460(ra) # 800041da <write_head>
}
    800043ae:	70a2                	ld	ra,40(sp)
    800043b0:	7402                	ld	s0,32(sp)
    800043b2:	64e2                	ld	s1,24(sp)
    800043b4:	6942                	ld	s2,16(sp)
    800043b6:	69a2                	ld	s3,8(sp)
    800043b8:	6145                	addi	sp,sp,48
    800043ba:	8082                	ret

00000000800043bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043bc:	1101                	addi	sp,sp,-32
    800043be:	ec06                	sd	ra,24(sp)
    800043c0:	e822                	sd	s0,16(sp)
    800043c2:	e426                	sd	s1,8(sp)
    800043c4:	e04a                	sd	s2,0(sp)
    800043c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043c8:	0001d517          	auipc	a0,0x1d
    800043cc:	35850513          	addi	a0,a0,856 # 80021720 <log>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	34848493          	addi	s1,s1,840 # 80021720 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e0:	4979                	li	s2,30
    800043e2:	a039                	j	800043f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043e4:	85a6                	mv	a1,s1
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	c94080e7          	jalr	-876(ra) # 8000207c <sleep>
    if(log.committing){
    800043f0:	50dc                	lw	a5,36(s1)
    800043f2:	fbed                	bnez	a5,800043e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043f4:	509c                	lw	a5,32(s1)
    800043f6:	0017871b          	addiw	a4,a5,1
    800043fa:	0007069b          	sext.w	a3,a4
    800043fe:	0027179b          	slliw	a5,a4,0x2
    80004402:	9fb9                	addw	a5,a5,a4
    80004404:	0017979b          	slliw	a5,a5,0x1
    80004408:	54d8                	lw	a4,44(s1)
    8000440a:	9fb9                	addw	a5,a5,a4
    8000440c:	00f95963          	bge	s2,a5,8000441e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004410:	85a6                	mv	a1,s1
    80004412:	8526                	mv	a0,s1
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	c68080e7          	jalr	-920(ra) # 8000207c <sleep>
    8000441c:	bfd1                	j	800043f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000441e:	0001d517          	auipc	a0,0x1d
    80004422:	30250513          	addi	a0,a0,770 # 80021720 <log>
    80004426:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004430:	60e2                	ld	ra,24(sp)
    80004432:	6442                	ld	s0,16(sp)
    80004434:	64a2                	ld	s1,8(sp)
    80004436:	6902                	ld	s2,0(sp)
    80004438:	6105                	addi	sp,sp,32
    8000443a:	8082                	ret

000000008000443c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000443c:	7139                	addi	sp,sp,-64
    8000443e:	fc06                	sd	ra,56(sp)
    80004440:	f822                	sd	s0,48(sp)
    80004442:	f426                	sd	s1,40(sp)
    80004444:	f04a                	sd	s2,32(sp)
    80004446:	ec4e                	sd	s3,24(sp)
    80004448:	e852                	sd	s4,16(sp)
    8000444a:	e456                	sd	s5,8(sp)
    8000444c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000444e:	0001d497          	auipc	s1,0x1d
    80004452:	2d248493          	addi	s1,s1,722 # 80021720 <log>
    80004456:	8526                	mv	a0,s1
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	77e080e7          	jalr	1918(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004460:	509c                	lw	a5,32(s1)
    80004462:	37fd                	addiw	a5,a5,-1
    80004464:	0007891b          	sext.w	s2,a5
    80004468:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000446a:	50dc                	lw	a5,36(s1)
    8000446c:	e7b9                	bnez	a5,800044ba <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000446e:	04091e63          	bnez	s2,800044ca <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004472:	0001d497          	auipc	s1,0x1d
    80004476:	2ae48493          	addi	s1,s1,686 # 80021720 <log>
    8000447a:	4785                	li	a5,1
    8000447c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	80a080e7          	jalr	-2038(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004488:	54dc                	lw	a5,44(s1)
    8000448a:	06f04763          	bgtz	a5,800044f8 <end_op+0xbc>
    acquire(&log.lock);
    8000448e:	0001d497          	auipc	s1,0x1d
    80004492:	29248493          	addi	s1,s1,658 # 80021720 <log>
    80004496:	8526                	mv	a0,s1
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	73e080e7          	jalr	1854(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044a4:	8526                	mv	a0,s1
    800044a6:	ffffe097          	auipc	ra,0xffffe
    800044aa:	c3a080e7          	jalr	-966(ra) # 800020e0 <wakeup>
    release(&log.lock);
    800044ae:	8526                	mv	a0,s1
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
}
    800044b8:	a03d                	j	800044e6 <end_op+0xaa>
    panic("log.committing");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	19650513          	addi	a0,a0,406 # 80008650 <syscalls+0x200>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>
    wakeup(&log);
    800044ca:	0001d497          	auipc	s1,0x1d
    800044ce:	25648493          	addi	s1,s1,598 # 80021720 <log>
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffe097          	auipc	ra,0xffffe
    800044d8:	c0c080e7          	jalr	-1012(ra) # 800020e0 <wakeup>
  release(&log.lock);
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7ac080e7          	jalr	1964(ra) # 80000c8a <release>
}
    800044e6:	70e2                	ld	ra,56(sp)
    800044e8:	7442                	ld	s0,48(sp)
    800044ea:	74a2                	ld	s1,40(sp)
    800044ec:	7902                	ld	s2,32(sp)
    800044ee:	69e2                	ld	s3,24(sp)
    800044f0:	6a42                	ld	s4,16(sp)
    800044f2:	6aa2                	ld	s5,8(sp)
    800044f4:	6121                	addi	sp,sp,64
    800044f6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f8:	0001da97          	auipc	s5,0x1d
    800044fc:	258a8a93          	addi	s5,s5,600 # 80021750 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004500:	0001da17          	auipc	s4,0x1d
    80004504:	220a0a13          	addi	s4,s4,544 # 80021720 <log>
    80004508:	018a2583          	lw	a1,24(s4)
    8000450c:	012585bb          	addw	a1,a1,s2
    80004510:	2585                	addiw	a1,a1,1
    80004512:	028a2503          	lw	a0,40(s4)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	cca080e7          	jalr	-822(ra) # 800031e0 <bread>
    8000451e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004520:	000aa583          	lw	a1,0(s5)
    80004524:	028a2503          	lw	a0,40(s4)
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	cb8080e7          	jalr	-840(ra) # 800031e0 <bread>
    80004530:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004532:	40000613          	li	a2,1024
    80004536:	05850593          	addi	a1,a0,88
    8000453a:	05848513          	addi	a0,s1,88
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	7f0080e7          	jalr	2032(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	d8a080e7          	jalr	-630(ra) # 800032d2 <bwrite>
    brelse(from);
    80004550:	854e                	mv	a0,s3
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	dbe080e7          	jalr	-578(ra) # 80003310 <brelse>
    brelse(to);
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	db4080e7          	jalr	-588(ra) # 80003310 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004564:	2905                	addiw	s2,s2,1
    80004566:	0a91                	addi	s5,s5,4
    80004568:	02ca2783          	lw	a5,44(s4)
    8000456c:	f8f94ee3          	blt	s2,a5,80004508 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004570:	00000097          	auipc	ra,0x0
    80004574:	c6a080e7          	jalr	-918(ra) # 800041da <write_head>
    install_trans(0); // Now install writes to home locations
    80004578:	4501                	li	a0,0
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	cda080e7          	jalr	-806(ra) # 80004254 <install_trans>
    log.lh.n = 0;
    80004582:	0001d797          	auipc	a5,0x1d
    80004586:	1c07a523          	sw	zero,458(a5) # 8002174c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	c50080e7          	jalr	-944(ra) # 800041da <write_head>
    80004592:	bdf5                	j	8000448e <end_op+0x52>

0000000080004594 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	e04a                	sd	s2,0(sp)
    8000459e:	1000                	addi	s0,sp,32
    800045a0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045a2:	0001d917          	auipc	s2,0x1d
    800045a6:	17e90913          	addi	s2,s2,382 # 80021720 <log>
    800045aa:	854a                	mv	a0,s2
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	62a080e7          	jalr	1578(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045b4:	02c92603          	lw	a2,44(s2)
    800045b8:	47f5                	li	a5,29
    800045ba:	06c7c563          	blt	a5,a2,80004624 <log_write+0x90>
    800045be:	0001d797          	auipc	a5,0x1d
    800045c2:	17e7a783          	lw	a5,382(a5) # 8002173c <log+0x1c>
    800045c6:	37fd                	addiw	a5,a5,-1
    800045c8:	04f65e63          	bge	a2,a5,80004624 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045cc:	0001d797          	auipc	a5,0x1d
    800045d0:	1747a783          	lw	a5,372(a5) # 80021740 <log+0x20>
    800045d4:	06f05063          	blez	a5,80004634 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045d8:	4781                	li	a5,0
    800045da:	06c05563          	blez	a2,80004644 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045de:	44cc                	lw	a1,12(s1)
    800045e0:	0001d717          	auipc	a4,0x1d
    800045e4:	17070713          	addi	a4,a4,368 # 80021750 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045e8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045ea:	4314                	lw	a3,0(a4)
    800045ec:	04b68c63          	beq	a3,a1,80004644 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045f0:	2785                	addiw	a5,a5,1
    800045f2:	0711                	addi	a4,a4,4
    800045f4:	fef61be3          	bne	a2,a5,800045ea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045f8:	0621                	addi	a2,a2,8
    800045fa:	060a                	slli	a2,a2,0x2
    800045fc:	0001d797          	auipc	a5,0x1d
    80004600:	12478793          	addi	a5,a5,292 # 80021720 <log>
    80004604:	963e                	add	a2,a2,a5
    80004606:	44dc                	lw	a5,12(s1)
    80004608:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000460a:	8526                	mv	a0,s1
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	da2080e7          	jalr	-606(ra) # 800033ae <bpin>
    log.lh.n++;
    80004614:	0001d717          	auipc	a4,0x1d
    80004618:	10c70713          	addi	a4,a4,268 # 80021720 <log>
    8000461c:	575c                	lw	a5,44(a4)
    8000461e:	2785                	addiw	a5,a5,1
    80004620:	d75c                	sw	a5,44(a4)
    80004622:	a835                	j	8000465e <log_write+0xca>
    panic("too big a transaction");
    80004624:	00004517          	auipc	a0,0x4
    80004628:	03c50513          	addi	a0,a0,60 # 80008660 <syscalls+0x210>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004634:	00004517          	auipc	a0,0x4
    80004638:	04450513          	addi	a0,a0,68 # 80008678 <syscalls+0x228>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004644:	00878713          	addi	a4,a5,8
    80004648:	00271693          	slli	a3,a4,0x2
    8000464c:	0001d717          	auipc	a4,0x1d
    80004650:	0d470713          	addi	a4,a4,212 # 80021720 <log>
    80004654:	9736                	add	a4,a4,a3
    80004656:	44d4                	lw	a3,12(s1)
    80004658:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000465a:	faf608e3          	beq	a2,a5,8000460a <log_write+0x76>
  }
  release(&log.lock);
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	0c250513          	addi	a0,a0,194 # 80021720 <log>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	624080e7          	jalr	1572(ra) # 80000c8a <release>
}
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6902                	ld	s2,0(sp)
    80004676:	6105                	addi	sp,sp,32
    80004678:	8082                	ret

000000008000467a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	e04a                	sd	s2,0(sp)
    80004684:	1000                	addi	s0,sp,32
    80004686:	84aa                	mv	s1,a0
    80004688:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000468a:	00004597          	auipc	a1,0x4
    8000468e:	00e58593          	addi	a1,a1,14 # 80008698 <syscalls+0x248>
    80004692:	0521                	addi	a0,a0,8
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	4b2080e7          	jalr	1202(ra) # 80000b46 <initlock>
  lk->name = name;
    8000469c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046a4:	0204a423          	sw	zero,40(s1)
}
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6902                	ld	s2,0(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	addi	s0,sp,32
    800046c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046c2:	00850913          	addi	s2,a0,8
    800046c6:	854a                	mv	a0,s2
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	50e080e7          	jalr	1294(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046d0:	409c                	lw	a5,0(s1)
    800046d2:	cb89                	beqz	a5,800046e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046d4:	85ca                	mv	a1,s2
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffe097          	auipc	ra,0xffffe
    800046dc:	9a4080e7          	jalr	-1628(ra) # 8000207c <sleep>
  while (lk->locked) {
    800046e0:	409c                	lw	a5,0(s1)
    800046e2:	fbed                	bnez	a5,800046d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046e4:	4785                	li	a5,1
    800046e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046e8:	ffffd097          	auipc	ra,0xffffd
    800046ec:	2c4080e7          	jalr	708(ra) # 800019ac <myproc>
    800046f0:	591c                	lw	a5,48(a0)
    800046f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046f4:	854a                	mv	a0,s2
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	594080e7          	jalr	1428(ra) # 80000c8a <release>
}
    800046fe:	60e2                	ld	ra,24(sp)
    80004700:	6442                	ld	s0,16(sp)
    80004702:	64a2                	ld	s1,8(sp)
    80004704:	6902                	ld	s2,0(sp)
    80004706:	6105                	addi	sp,sp,32
    80004708:	8082                	ret

000000008000470a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
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
  lk->locked = 0;
    80004726:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000472a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffe097          	auipc	ra,0xffffe
    80004734:	9b0080e7          	jalr	-1616(ra) # 800020e0 <wakeup>
  release(&lk->lk);
    80004738:	854a                	mv	a0,s2
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	550080e7          	jalr	1360(ra) # 80000c8a <release>
}
    80004742:	60e2                	ld	ra,24(sp)
    80004744:	6442                	ld	s0,16(sp)
    80004746:	64a2                	ld	s1,8(sp)
    80004748:	6902                	ld	s2,0(sp)
    8000474a:	6105                	addi	sp,sp,32
    8000474c:	8082                	ret

000000008000474e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000474e:	7179                	addi	sp,sp,-48
    80004750:	f406                	sd	ra,40(sp)
    80004752:	f022                	sd	s0,32(sp)
    80004754:	ec26                	sd	s1,24(sp)
    80004756:	e84a                	sd	s2,16(sp)
    80004758:	e44e                	sd	s3,8(sp)
    8000475a:	1800                	addi	s0,sp,48
    8000475c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000475e:	00850913          	addi	s2,a0,8
    80004762:	854a                	mv	a0,s2
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	472080e7          	jalr	1138(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000476c:	409c                	lw	a5,0(s1)
    8000476e:	ef99                	bnez	a5,8000478c <holdingsleep+0x3e>
    80004770:	4481                	li	s1,0
  release(&lk->lk);
    80004772:	854a                	mv	a0,s2
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
  return r;
}
    8000477c:	8526                	mv	a0,s1
    8000477e:	70a2                	ld	ra,40(sp)
    80004780:	7402                	ld	s0,32(sp)
    80004782:	64e2                	ld	s1,24(sp)
    80004784:	6942                	ld	s2,16(sp)
    80004786:	69a2                	ld	s3,8(sp)
    80004788:	6145                	addi	sp,sp,48
    8000478a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000478c:	0284a983          	lw	s3,40(s1)
    80004790:	ffffd097          	auipc	ra,0xffffd
    80004794:	21c080e7          	jalr	540(ra) # 800019ac <myproc>
    80004798:	5904                	lw	s1,48(a0)
    8000479a:	413484b3          	sub	s1,s1,s3
    8000479e:	0014b493          	seqz	s1,s1
    800047a2:	bfc1                	j	80004772 <holdingsleep+0x24>

00000000800047a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047a4:	1141                	addi	sp,sp,-16
    800047a6:	e406                	sd	ra,8(sp)
    800047a8:	e022                	sd	s0,0(sp)
    800047aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047ac:	00004597          	auipc	a1,0x4
    800047b0:	efc58593          	addi	a1,a1,-260 # 800086a8 <syscalls+0x258>
    800047b4:	0001d517          	auipc	a0,0x1d
    800047b8:	0b450513          	addi	a0,a0,180 # 80021868 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	38a080e7          	jalr	906(ra) # 80000b46 <initlock>
}
    800047c4:	60a2                	ld	ra,8(sp)
    800047c6:	6402                	ld	s0,0(sp)
    800047c8:	0141                	addi	sp,sp,16
    800047ca:	8082                	ret

00000000800047cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047d6:	0001d517          	auipc	a0,0x1d
    800047da:	09250513          	addi	a0,a0,146 # 80021868 <ftable>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	3f8080e7          	jalr	1016(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047e6:	0001d497          	auipc	s1,0x1d
    800047ea:	09a48493          	addi	s1,s1,154 # 80021880 <ftable+0x18>
    800047ee:	0001e717          	auipc	a4,0x1e
    800047f2:	03270713          	addi	a4,a4,50 # 80022820 <disk>
    if(f->ref == 0){
    800047f6:	40dc                	lw	a5,4(s1)
    800047f8:	cf99                	beqz	a5,80004816 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047fa:	02848493          	addi	s1,s1,40
    800047fe:	fee49ce3          	bne	s1,a4,800047f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004802:	0001d517          	auipc	a0,0x1d
    80004806:	06650513          	addi	a0,a0,102 # 80021868 <ftable>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	480080e7          	jalr	1152(ra) # 80000c8a <release>
  return 0;
    80004812:	4481                	li	s1,0
    80004814:	a819                	j	8000482a <filealloc+0x5e>
      f->ref = 1;
    80004816:	4785                	li	a5,1
    80004818:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000481a:	0001d517          	auipc	a0,0x1d
    8000481e:	04e50513          	addi	a0,a0,78 # 80021868 <ftable>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	468080e7          	jalr	1128(ra) # 80000c8a <release>
}
    8000482a:	8526                	mv	a0,s1
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6105                	addi	sp,sp,32
    80004834:	8082                	ret

0000000080004836 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004836:	1101                	addi	sp,sp,-32
    80004838:	ec06                	sd	ra,24(sp)
    8000483a:	e822                	sd	s0,16(sp)
    8000483c:	e426                	sd	s1,8(sp)
    8000483e:	1000                	addi	s0,sp,32
    80004840:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004842:	0001d517          	auipc	a0,0x1d
    80004846:	02650513          	addi	a0,a0,38 # 80021868 <ftable>
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	38c080e7          	jalr	908(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004852:	40dc                	lw	a5,4(s1)
    80004854:	02f05263          	blez	a5,80004878 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004858:	2785                	addiw	a5,a5,1
    8000485a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000485c:	0001d517          	auipc	a0,0x1d
    80004860:	00c50513          	addi	a0,a0,12 # 80021868 <ftable>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	426080e7          	jalr	1062(ra) # 80000c8a <release>
  return f;
}
    8000486c:	8526                	mv	a0,s1
    8000486e:	60e2                	ld	ra,24(sp)
    80004870:	6442                	ld	s0,16(sp)
    80004872:	64a2                	ld	s1,8(sp)
    80004874:	6105                	addi	sp,sp,32
    80004876:	8082                	ret
    panic("filedup");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	e3850513          	addi	a0,a0,-456 # 800086b0 <syscalls+0x260>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>

0000000080004888 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004888:	7139                	addi	sp,sp,-64
    8000488a:	fc06                	sd	ra,56(sp)
    8000488c:	f822                	sd	s0,48(sp)
    8000488e:	f426                	sd	s1,40(sp)
    80004890:	f04a                	sd	s2,32(sp)
    80004892:	ec4e                	sd	s3,24(sp)
    80004894:	e852                	sd	s4,16(sp)
    80004896:	e456                	sd	s5,8(sp)
    80004898:	0080                	addi	s0,sp,64
    8000489a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000489c:	0001d517          	auipc	a0,0x1d
    800048a0:	fcc50513          	addi	a0,a0,-52 # 80021868 <ftable>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	332080e7          	jalr	818(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048ac:	40dc                	lw	a5,4(s1)
    800048ae:	06f05163          	blez	a5,80004910 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048b2:	37fd                	addiw	a5,a5,-1
    800048b4:	0007871b          	sext.w	a4,a5
    800048b8:	c0dc                	sw	a5,4(s1)
    800048ba:	06e04363          	bgtz	a4,80004920 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048be:	0004a903          	lw	s2,0(s1)
    800048c2:	0094ca83          	lbu	s5,9(s1)
    800048c6:	0104ba03          	ld	s4,16(s1)
    800048ca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048d2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048d6:	0001d517          	auipc	a0,0x1d
    800048da:	f9250513          	addi	a0,a0,-110 # 80021868 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	3ac080e7          	jalr	940(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048e6:	4785                	li	a5,1
    800048e8:	04f90d63          	beq	s2,a5,80004942 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048ec:	3979                	addiw	s2,s2,-2
    800048ee:	4785                	li	a5,1
    800048f0:	0527e063          	bltu	a5,s2,80004930 <fileclose+0xa8>
    begin_op();
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	ac8080e7          	jalr	-1336(ra) # 800043bc <begin_op>
    iput(ff.ip);
    800048fc:	854e                	mv	a0,s3
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	2b6080e7          	jalr	694(ra) # 80003bb4 <iput>
    end_op();
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	b36080e7          	jalr	-1226(ra) # 8000443c <end_op>
    8000490e:	a00d                	j	80004930 <fileclose+0xa8>
    panic("fileclose");
    80004910:	00004517          	auipc	a0,0x4
    80004914:	da850513          	addi	a0,a0,-600 # 800086b8 <syscalls+0x268>
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	c26080e7          	jalr	-986(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004920:	0001d517          	auipc	a0,0x1d
    80004924:	f4850513          	addi	a0,a0,-184 # 80021868 <ftable>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	362080e7          	jalr	866(ra) # 80000c8a <release>
  }
}
    80004930:	70e2                	ld	ra,56(sp)
    80004932:	7442                	ld	s0,48(sp)
    80004934:	74a2                	ld	s1,40(sp)
    80004936:	7902                	ld	s2,32(sp)
    80004938:	69e2                	ld	s3,24(sp)
    8000493a:	6a42                	ld	s4,16(sp)
    8000493c:	6aa2                	ld	s5,8(sp)
    8000493e:	6121                	addi	sp,sp,64
    80004940:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004942:	85d6                	mv	a1,s5
    80004944:	8552                	mv	a0,s4
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	34c080e7          	jalr	844(ra) # 80004c92 <pipeclose>
    8000494e:	b7cd                	j	80004930 <fileclose+0xa8>

0000000080004950 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004950:	715d                	addi	sp,sp,-80
    80004952:	e486                	sd	ra,72(sp)
    80004954:	e0a2                	sd	s0,64(sp)
    80004956:	fc26                	sd	s1,56(sp)
    80004958:	f84a                	sd	s2,48(sp)
    8000495a:	f44e                	sd	s3,40(sp)
    8000495c:	0880                	addi	s0,sp,80
    8000495e:	84aa                	mv	s1,a0
    80004960:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004962:	ffffd097          	auipc	ra,0xffffd
    80004966:	04a080e7          	jalr	74(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000496a:	409c                	lw	a5,0(s1)
    8000496c:	37f9                	addiw	a5,a5,-2
    8000496e:	4705                	li	a4,1
    80004970:	04f76763          	bltu	a4,a5,800049be <filestat+0x6e>
    80004974:	892a                	mv	s2,a0
    ilock(f->ip);
    80004976:	6c88                	ld	a0,24(s1)
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	082080e7          	jalr	130(ra) # 800039fa <ilock>
    stati(f->ip, &st);
    80004980:	fb840593          	addi	a1,s0,-72
    80004984:	6c88                	ld	a0,24(s1)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	2fe080e7          	jalr	766(ra) # 80003c84 <stati>
    iunlock(f->ip);
    8000498e:	6c88                	ld	a0,24(s1)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	12c080e7          	jalr	300(ra) # 80003abc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004998:	46e1                	li	a3,24
    8000499a:	fb840613          	addi	a2,s0,-72
    8000499e:	85ce                	mv	a1,s3
    800049a0:	05893503          	ld	a0,88(s2)
    800049a4:	ffffd097          	auipc	ra,0xffffd
    800049a8:	cc4080e7          	jalr	-828(ra) # 80001668 <copyout>
    800049ac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049b0:	60a6                	ld	ra,72(sp)
    800049b2:	6406                	ld	s0,64(sp)
    800049b4:	74e2                	ld	s1,56(sp)
    800049b6:	7942                	ld	s2,48(sp)
    800049b8:	79a2                	ld	s3,40(sp)
    800049ba:	6161                	addi	sp,sp,80
    800049bc:	8082                	ret
  return -1;
    800049be:	557d                	li	a0,-1
    800049c0:	bfc5                	j	800049b0 <filestat+0x60>

00000000800049c2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049c2:	7179                	addi	sp,sp,-48
    800049c4:	f406                	sd	ra,40(sp)
    800049c6:	f022                	sd	s0,32(sp)
    800049c8:	ec26                	sd	s1,24(sp)
    800049ca:	e84a                	sd	s2,16(sp)
    800049cc:	e44e                	sd	s3,8(sp)
    800049ce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049d0:	00854783          	lbu	a5,8(a0)
    800049d4:	c3d5                	beqz	a5,80004a78 <fileread+0xb6>
    800049d6:	84aa                	mv	s1,a0
    800049d8:	89ae                	mv	s3,a1
    800049da:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049dc:	411c                	lw	a5,0(a0)
    800049de:	4705                	li	a4,1
    800049e0:	04e78963          	beq	a5,a4,80004a32 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049e4:	470d                	li	a4,3
    800049e6:	04e78d63          	beq	a5,a4,80004a40 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ea:	4709                	li	a4,2
    800049ec:	06e79e63          	bne	a5,a4,80004a68 <fileread+0xa6>
    ilock(f->ip);
    800049f0:	6d08                	ld	a0,24(a0)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	008080e7          	jalr	8(ra) # 800039fa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049fa:	874a                	mv	a4,s2
    800049fc:	5094                	lw	a3,32(s1)
    800049fe:	864e                	mv	a2,s3
    80004a00:	4585                	li	a1,1
    80004a02:	6c88                	ld	a0,24(s1)
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	2aa080e7          	jalr	682(ra) # 80003cae <readi>
    80004a0c:	892a                	mv	s2,a0
    80004a0e:	00a05563          	blez	a0,80004a18 <fileread+0x56>
      f->off += r;
    80004a12:	509c                	lw	a5,32(s1)
    80004a14:	9fa9                	addw	a5,a5,a0
    80004a16:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a18:	6c88                	ld	a0,24(s1)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	0a2080e7          	jalr	162(ra) # 80003abc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a22:	854a                	mv	a0,s2
    80004a24:	70a2                	ld	ra,40(sp)
    80004a26:	7402                	ld	s0,32(sp)
    80004a28:	64e2                	ld	s1,24(sp)
    80004a2a:	6942                	ld	s2,16(sp)
    80004a2c:	69a2                	ld	s3,8(sp)
    80004a2e:	6145                	addi	sp,sp,48
    80004a30:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a32:	6908                	ld	a0,16(a0)
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	3c6080e7          	jalr	966(ra) # 80004dfa <piperead>
    80004a3c:	892a                	mv	s2,a0
    80004a3e:	b7d5                	j	80004a22 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a40:	02451783          	lh	a5,36(a0)
    80004a44:	03079693          	slli	a3,a5,0x30
    80004a48:	92c1                	srli	a3,a3,0x30
    80004a4a:	4725                	li	a4,9
    80004a4c:	02d76863          	bltu	a4,a3,80004a7c <fileread+0xba>
    80004a50:	0792                	slli	a5,a5,0x4
    80004a52:	0001d717          	auipc	a4,0x1d
    80004a56:	d7670713          	addi	a4,a4,-650 # 800217c8 <devsw>
    80004a5a:	97ba                	add	a5,a5,a4
    80004a5c:	639c                	ld	a5,0(a5)
    80004a5e:	c38d                	beqz	a5,80004a80 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a60:	4505                	li	a0,1
    80004a62:	9782                	jalr	a5
    80004a64:	892a                	mv	s2,a0
    80004a66:	bf75                	j	80004a22 <fileread+0x60>
    panic("fileread");
    80004a68:	00004517          	auipc	a0,0x4
    80004a6c:	c6050513          	addi	a0,a0,-928 # 800086c8 <syscalls+0x278>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	ace080e7          	jalr	-1330(ra) # 8000053e <panic>
    return -1;
    80004a78:	597d                	li	s2,-1
    80004a7a:	b765                	j	80004a22 <fileread+0x60>
      return -1;
    80004a7c:	597d                	li	s2,-1
    80004a7e:	b755                	j	80004a22 <fileread+0x60>
    80004a80:	597d                	li	s2,-1
    80004a82:	b745                	j	80004a22 <fileread+0x60>

0000000080004a84 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a84:	715d                	addi	sp,sp,-80
    80004a86:	e486                	sd	ra,72(sp)
    80004a88:	e0a2                	sd	s0,64(sp)
    80004a8a:	fc26                	sd	s1,56(sp)
    80004a8c:	f84a                	sd	s2,48(sp)
    80004a8e:	f44e                	sd	s3,40(sp)
    80004a90:	f052                	sd	s4,32(sp)
    80004a92:	ec56                	sd	s5,24(sp)
    80004a94:	e85a                	sd	s6,16(sp)
    80004a96:	e45e                	sd	s7,8(sp)
    80004a98:	e062                	sd	s8,0(sp)
    80004a9a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a9c:	00954783          	lbu	a5,9(a0)
    80004aa0:	10078663          	beqz	a5,80004bac <filewrite+0x128>
    80004aa4:	892a                	mv	s2,a0
    80004aa6:	8aae                	mv	s5,a1
    80004aa8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aaa:	411c                	lw	a5,0(a0)
    80004aac:	4705                	li	a4,1
    80004aae:	02e78263          	beq	a5,a4,80004ad2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ab2:	470d                	li	a4,3
    80004ab4:	02e78663          	beq	a5,a4,80004ae0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ab8:	4709                	li	a4,2
    80004aba:	0ee79163          	bne	a5,a4,80004b9c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004abe:	0ac05d63          	blez	a2,80004b78 <filewrite+0xf4>
    int i = 0;
    80004ac2:	4981                	li	s3,0
    80004ac4:	6b05                	lui	s6,0x1
    80004ac6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aca:	6b85                	lui	s7,0x1
    80004acc:	c00b8b9b          	addiw	s7,s7,-1024
    80004ad0:	a861                	j	80004b68 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ad2:	6908                	ld	a0,16(a0)
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	22e080e7          	jalr	558(ra) # 80004d02 <pipewrite>
    80004adc:	8a2a                	mv	s4,a0
    80004ade:	a045                	j	80004b7e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ae0:	02451783          	lh	a5,36(a0)
    80004ae4:	03079693          	slli	a3,a5,0x30
    80004ae8:	92c1                	srli	a3,a3,0x30
    80004aea:	4725                	li	a4,9
    80004aec:	0cd76263          	bltu	a4,a3,80004bb0 <filewrite+0x12c>
    80004af0:	0792                	slli	a5,a5,0x4
    80004af2:	0001d717          	auipc	a4,0x1d
    80004af6:	cd670713          	addi	a4,a4,-810 # 800217c8 <devsw>
    80004afa:	97ba                	add	a5,a5,a4
    80004afc:	679c                	ld	a5,8(a5)
    80004afe:	cbdd                	beqz	a5,80004bb4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b00:	4505                	li	a0,1
    80004b02:	9782                	jalr	a5
    80004b04:	8a2a                	mv	s4,a0
    80004b06:	a8a5                	j	80004b7e <filewrite+0xfa>
    80004b08:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	8b0080e7          	jalr	-1872(ra) # 800043bc <begin_op>
      ilock(f->ip);
    80004b14:	01893503          	ld	a0,24(s2)
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	ee2080e7          	jalr	-286(ra) # 800039fa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b20:	8762                	mv	a4,s8
    80004b22:	02092683          	lw	a3,32(s2)
    80004b26:	01598633          	add	a2,s3,s5
    80004b2a:	4585                	li	a1,1
    80004b2c:	01893503          	ld	a0,24(s2)
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	276080e7          	jalr	630(ra) # 80003da6 <writei>
    80004b38:	84aa                	mv	s1,a0
    80004b3a:	00a05763          	blez	a0,80004b48 <filewrite+0xc4>
        f->off += r;
    80004b3e:	02092783          	lw	a5,32(s2)
    80004b42:	9fa9                	addw	a5,a5,a0
    80004b44:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b48:	01893503          	ld	a0,24(s2)
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	f70080e7          	jalr	-144(ra) # 80003abc <iunlock>
      end_op();
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	8e8080e7          	jalr	-1816(ra) # 8000443c <end_op>

      if(r != n1){
    80004b5c:	009c1f63          	bne	s8,s1,80004b7a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b60:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b64:	0149db63          	bge	s3,s4,80004b7a <filewrite+0xf6>
      int n1 = n - i;
    80004b68:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b6c:	84be                	mv	s1,a5
    80004b6e:	2781                	sext.w	a5,a5
    80004b70:	f8fb5ce3          	bge	s6,a5,80004b08 <filewrite+0x84>
    80004b74:	84de                	mv	s1,s7
    80004b76:	bf49                	j	80004b08 <filewrite+0x84>
    int i = 0;
    80004b78:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b7a:	013a1f63          	bne	s4,s3,80004b98 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b7e:	8552                	mv	a0,s4
    80004b80:	60a6                	ld	ra,72(sp)
    80004b82:	6406                	ld	s0,64(sp)
    80004b84:	74e2                	ld	s1,56(sp)
    80004b86:	7942                	ld	s2,48(sp)
    80004b88:	79a2                	ld	s3,40(sp)
    80004b8a:	7a02                	ld	s4,32(sp)
    80004b8c:	6ae2                	ld	s5,24(sp)
    80004b8e:	6b42                	ld	s6,16(sp)
    80004b90:	6ba2                	ld	s7,8(sp)
    80004b92:	6c02                	ld	s8,0(sp)
    80004b94:	6161                	addi	sp,sp,80
    80004b96:	8082                	ret
    ret = (i == n ? n : -1);
    80004b98:	5a7d                	li	s4,-1
    80004b9a:	b7d5                	j	80004b7e <filewrite+0xfa>
    panic("filewrite");
    80004b9c:	00004517          	auipc	a0,0x4
    80004ba0:	b3c50513          	addi	a0,a0,-1220 # 800086d8 <syscalls+0x288>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	99a080e7          	jalr	-1638(ra) # 8000053e <panic>
    return -1;
    80004bac:	5a7d                	li	s4,-1
    80004bae:	bfc1                	j	80004b7e <filewrite+0xfa>
      return -1;
    80004bb0:	5a7d                	li	s4,-1
    80004bb2:	b7f1                	j	80004b7e <filewrite+0xfa>
    80004bb4:	5a7d                	li	s4,-1
    80004bb6:	b7e1                	j	80004b7e <filewrite+0xfa>

0000000080004bb8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bb8:	7179                	addi	sp,sp,-48
    80004bba:	f406                	sd	ra,40(sp)
    80004bbc:	f022                	sd	s0,32(sp)
    80004bbe:	ec26                	sd	s1,24(sp)
    80004bc0:	e84a                	sd	s2,16(sp)
    80004bc2:	e44e                	sd	s3,8(sp)
    80004bc4:	e052                	sd	s4,0(sp)
    80004bc6:	1800                	addi	s0,sp,48
    80004bc8:	84aa                	mv	s1,a0
    80004bca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bcc:	0005b023          	sd	zero,0(a1)
    80004bd0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bd4:	00000097          	auipc	ra,0x0
    80004bd8:	bf8080e7          	jalr	-1032(ra) # 800047cc <filealloc>
    80004bdc:	e088                	sd	a0,0(s1)
    80004bde:	c551                	beqz	a0,80004c6a <pipealloc+0xb2>
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	bec080e7          	jalr	-1044(ra) # 800047cc <filealloc>
    80004be8:	00aa3023          	sd	a0,0(s4)
    80004bec:	c92d                	beqz	a0,80004c5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	ef8080e7          	jalr	-264(ra) # 80000ae6 <kalloc>
    80004bf6:	892a                	mv	s2,a0
    80004bf8:	c125                	beqz	a0,80004c58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bfa:	4985                	li	s3,1
    80004bfc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c0c:	00004597          	auipc	a1,0x4
    80004c10:	adc58593          	addi	a1,a1,-1316 # 800086e8 <syscalls+0x298>
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	f32080e7          	jalr	-206(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c1c:	609c                	ld	a5,0(s1)
    80004c1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c22:	609c                	ld	a5,0(s1)
    80004c24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c28:	609c                	ld	a5,0(s1)
    80004c2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c2e:	609c                	ld	a5,0(s1)
    80004c30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c34:	000a3783          	ld	a5,0(s4)
    80004c38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c3c:	000a3783          	ld	a5,0(s4)
    80004c40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c44:	000a3783          	ld	a5,0(s4)
    80004c48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c4c:	000a3783          	ld	a5,0(s4)
    80004c50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c54:	4501                	li	a0,0
    80004c56:	a025                	j	80004c7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c58:	6088                	ld	a0,0(s1)
    80004c5a:	e501                	bnez	a0,80004c62 <pipealloc+0xaa>
    80004c5c:	a039                	j	80004c6a <pipealloc+0xb2>
    80004c5e:	6088                	ld	a0,0(s1)
    80004c60:	c51d                	beqz	a0,80004c8e <pipealloc+0xd6>
    fileclose(*f0);
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	c26080e7          	jalr	-986(ra) # 80004888 <fileclose>
  if(*f1)
    80004c6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c6e:	557d                	li	a0,-1
  if(*f1)
    80004c70:	c799                	beqz	a5,80004c7e <pipealloc+0xc6>
    fileclose(*f1);
    80004c72:	853e                	mv	a0,a5
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	c14080e7          	jalr	-1004(ra) # 80004888 <fileclose>
  return -1;
    80004c7c:	557d                	li	a0,-1
}
    80004c7e:	70a2                	ld	ra,40(sp)
    80004c80:	7402                	ld	s0,32(sp)
    80004c82:	64e2                	ld	s1,24(sp)
    80004c84:	6942                	ld	s2,16(sp)
    80004c86:	69a2                	ld	s3,8(sp)
    80004c88:	6a02                	ld	s4,0(sp)
    80004c8a:	6145                	addi	sp,sp,48
    80004c8c:	8082                	ret
  return -1;
    80004c8e:	557d                	li	a0,-1
    80004c90:	b7fd                	j	80004c7e <pipealloc+0xc6>

0000000080004c92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c92:	1101                	addi	sp,sp,-32
    80004c94:	ec06                	sd	ra,24(sp)
    80004c96:	e822                	sd	s0,16(sp)
    80004c98:	e426                	sd	s1,8(sp)
    80004c9a:	e04a                	sd	s2,0(sp)
    80004c9c:	1000                	addi	s0,sp,32
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	f34080e7          	jalr	-204(ra) # 80000bd6 <acquire>
  if(writable){
    80004caa:	02090d63          	beqz	s2,80004ce4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cb2:	21848513          	addi	a0,s1,536
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	42a080e7          	jalr	1066(ra) # 800020e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cbe:	2204b783          	ld	a5,544(s1)
    80004cc2:	eb95                	bnez	a5,80004cf6 <pipeclose+0x64>
    release(&pi->lock);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	fc4080e7          	jalr	-60(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	d1a080e7          	jalr	-742(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004cd8:	60e2                	ld	ra,24(sp)
    80004cda:	6442                	ld	s0,16(sp)
    80004cdc:	64a2                	ld	s1,8(sp)
    80004cde:	6902                	ld	s2,0(sp)
    80004ce0:	6105                	addi	sp,sp,32
    80004ce2:	8082                	ret
    pi->readopen = 0;
    80004ce4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ce8:	21c48513          	addi	a0,s1,540
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	3f4080e7          	jalr	1012(ra) # 800020e0 <wakeup>
    80004cf4:	b7e9                	j	80004cbe <pipeclose+0x2c>
    release(&pi->lock);
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	f92080e7          	jalr	-110(ra) # 80000c8a <release>
}
    80004d00:	bfe1                	j	80004cd8 <pipeclose+0x46>

0000000080004d02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d02:	711d                	addi	sp,sp,-96
    80004d04:	ec86                	sd	ra,88(sp)
    80004d06:	e8a2                	sd	s0,80(sp)
    80004d08:	e4a6                	sd	s1,72(sp)
    80004d0a:	e0ca                	sd	s2,64(sp)
    80004d0c:	fc4e                	sd	s3,56(sp)
    80004d0e:	f852                	sd	s4,48(sp)
    80004d10:	f456                	sd	s5,40(sp)
    80004d12:	f05a                	sd	s6,32(sp)
    80004d14:	ec5e                	sd	s7,24(sp)
    80004d16:	e862                	sd	s8,16(sp)
    80004d18:	1080                	addi	s0,sp,96
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	8aae                	mv	s5,a1
    80004d1e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d20:	ffffd097          	auipc	ra,0xffffd
    80004d24:	c8c080e7          	jalr	-884(ra) # 800019ac <myproc>
    80004d28:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	eaa080e7          	jalr	-342(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d34:	0b405663          	blez	s4,80004de0 <pipewrite+0xde>
  int i = 0;
    80004d38:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d3c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d40:	21c48b93          	addi	s7,s1,540
    80004d44:	a089                	j	80004d86 <pipewrite+0x84>
      release(&pi->lock);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	f42080e7          	jalr	-190(ra) # 80000c8a <release>
      return -1;
    80004d50:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d52:	854a                	mv	a0,s2
    80004d54:	60e6                	ld	ra,88(sp)
    80004d56:	6446                	ld	s0,80(sp)
    80004d58:	64a6                	ld	s1,72(sp)
    80004d5a:	6906                	ld	s2,64(sp)
    80004d5c:	79e2                	ld	s3,56(sp)
    80004d5e:	7a42                	ld	s4,48(sp)
    80004d60:	7aa2                	ld	s5,40(sp)
    80004d62:	7b02                	ld	s6,32(sp)
    80004d64:	6be2                	ld	s7,24(sp)
    80004d66:	6c42                	ld	s8,16(sp)
    80004d68:	6125                	addi	sp,sp,96
    80004d6a:	8082                	ret
      wakeup(&pi->nread);
    80004d6c:	8562                	mv	a0,s8
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	372080e7          	jalr	882(ra) # 800020e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d76:	85a6                	mv	a1,s1
    80004d78:	855e                	mv	a0,s7
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	302080e7          	jalr	770(ra) # 8000207c <sleep>
  while(i < n){
    80004d82:	07495063          	bge	s2,s4,80004de2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d86:	2204a783          	lw	a5,544(s1)
    80004d8a:	dfd5                	beqz	a5,80004d46 <pipewrite+0x44>
    80004d8c:	854e                	mv	a0,s3
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	5a2080e7          	jalr	1442(ra) # 80002330 <killed>
    80004d96:	f945                	bnez	a0,80004d46 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d98:	2184a783          	lw	a5,536(s1)
    80004d9c:	21c4a703          	lw	a4,540(s1)
    80004da0:	2007879b          	addiw	a5,a5,512
    80004da4:	fcf704e3          	beq	a4,a5,80004d6c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da8:	4685                	li	a3,1
    80004daa:	01590633          	add	a2,s2,s5
    80004dae:	faf40593          	addi	a1,s0,-81
    80004db2:	0589b503          	ld	a0,88(s3)
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	93e080e7          	jalr	-1730(ra) # 800016f4 <copyin>
    80004dbe:	03650263          	beq	a0,s6,80004de2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dc2:	21c4a783          	lw	a5,540(s1)
    80004dc6:	0017871b          	addiw	a4,a5,1
    80004dca:	20e4ae23          	sw	a4,540(s1)
    80004dce:	1ff7f793          	andi	a5,a5,511
    80004dd2:	97a6                	add	a5,a5,s1
    80004dd4:	faf44703          	lbu	a4,-81(s0)
    80004dd8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ddc:	2905                	addiw	s2,s2,1
    80004dde:	b755                	j	80004d82 <pipewrite+0x80>
  int i = 0;
    80004de0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004de2:	21848513          	addi	a0,s1,536
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	2fa080e7          	jalr	762(ra) # 800020e0 <wakeup>
  release(&pi->lock);
    80004dee:	8526                	mv	a0,s1
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	e9a080e7          	jalr	-358(ra) # 80000c8a <release>
  return i;
    80004df8:	bfa9                	j	80004d52 <pipewrite+0x50>

0000000080004dfa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dfa:	715d                	addi	sp,sp,-80
    80004dfc:	e486                	sd	ra,72(sp)
    80004dfe:	e0a2                	sd	s0,64(sp)
    80004e00:	fc26                	sd	s1,56(sp)
    80004e02:	f84a                	sd	s2,48(sp)
    80004e04:	f44e                	sd	s3,40(sp)
    80004e06:	f052                	sd	s4,32(sp)
    80004e08:	ec56                	sd	s5,24(sp)
    80004e0a:	e85a                	sd	s6,16(sp)
    80004e0c:	0880                	addi	s0,sp,80
    80004e0e:	84aa                	mv	s1,a0
    80004e10:	892e                	mv	s2,a1
    80004e12:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	b98080e7          	jalr	-1128(ra) # 800019ac <myproc>
    80004e1c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	db6080e7          	jalr	-586(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e28:	2184a703          	lw	a4,536(s1)
    80004e2c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e30:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e34:	02f71763          	bne	a4,a5,80004e62 <piperead+0x68>
    80004e38:	2244a783          	lw	a5,548(s1)
    80004e3c:	c39d                	beqz	a5,80004e62 <piperead+0x68>
    if(killed(pr)){
    80004e3e:	8552                	mv	a0,s4
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	4f0080e7          	jalr	1264(ra) # 80002330 <killed>
    80004e48:	e941                	bnez	a0,80004ed8 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e4a:	85a6                	mv	a1,s1
    80004e4c:	854e                	mv	a0,s3
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	22e080e7          	jalr	558(ra) # 8000207c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e56:	2184a703          	lw	a4,536(s1)
    80004e5a:	21c4a783          	lw	a5,540(s1)
    80004e5e:	fcf70de3          	beq	a4,a5,80004e38 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e62:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e64:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e66:	05505363          	blez	s5,80004eac <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004e6a:	2184a783          	lw	a5,536(s1)
    80004e6e:	21c4a703          	lw	a4,540(s1)
    80004e72:	02f70d63          	beq	a4,a5,80004eac <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e76:	0017871b          	addiw	a4,a5,1
    80004e7a:	20e4ac23          	sw	a4,536(s1)
    80004e7e:	1ff7f793          	andi	a5,a5,511
    80004e82:	97a6                	add	a5,a5,s1
    80004e84:	0187c783          	lbu	a5,24(a5)
    80004e88:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e8c:	4685                	li	a3,1
    80004e8e:	fbf40613          	addi	a2,s0,-65
    80004e92:	85ca                	mv	a1,s2
    80004e94:	058a3503          	ld	a0,88(s4)
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	7d0080e7          	jalr	2000(ra) # 80001668 <copyout>
    80004ea0:	01650663          	beq	a0,s6,80004eac <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ea4:	2985                	addiw	s3,s3,1
    80004ea6:	0905                	addi	s2,s2,1
    80004ea8:	fd3a91e3          	bne	s5,s3,80004e6a <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eac:	21c48513          	addi	a0,s1,540
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	230080e7          	jalr	560(ra) # 800020e0 <wakeup>
  release(&pi->lock);
    80004eb8:	8526                	mv	a0,s1
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	dd0080e7          	jalr	-560(ra) # 80000c8a <release>
  return i;
}
    80004ec2:	854e                	mv	a0,s3
    80004ec4:	60a6                	ld	ra,72(sp)
    80004ec6:	6406                	ld	s0,64(sp)
    80004ec8:	74e2                	ld	s1,56(sp)
    80004eca:	7942                	ld	s2,48(sp)
    80004ecc:	79a2                	ld	s3,40(sp)
    80004ece:	7a02                	ld	s4,32(sp)
    80004ed0:	6ae2                	ld	s5,24(sp)
    80004ed2:	6b42                	ld	s6,16(sp)
    80004ed4:	6161                	addi	sp,sp,80
    80004ed6:	8082                	ret
      release(&pi->lock);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	db0080e7          	jalr	-592(ra) # 80000c8a <release>
      return -1;
    80004ee2:	59fd                	li	s3,-1
    80004ee4:	bff9                	j	80004ec2 <piperead+0xc8>

0000000080004ee6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ee6:	1141                	addi	sp,sp,-16
    80004ee8:	e422                	sd	s0,8(sp)
    80004eea:	0800                	addi	s0,sp,16
    80004eec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004eee:	8905                	andi	a0,a0,1
    80004ef0:	c111                	beqz	a0,80004ef4 <flags2perm+0xe>
      perm = PTE_X;
    80004ef2:	4521                	li	a0,8
    if(flags & 0x2)
    80004ef4:	8b89                	andi	a5,a5,2
    80004ef6:	c399                	beqz	a5,80004efc <flags2perm+0x16>
      perm |= PTE_W;
    80004ef8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004efc:	6422                	ld	s0,8(sp)
    80004efe:	0141                	addi	sp,sp,16
    80004f00:	8082                	ret

0000000080004f02 <exec>:

int
exec(char *path, char **argv)
{
    80004f02:	de010113          	addi	sp,sp,-544
    80004f06:	20113c23          	sd	ra,536(sp)
    80004f0a:	20813823          	sd	s0,528(sp)
    80004f0e:	20913423          	sd	s1,520(sp)
    80004f12:	21213023          	sd	s2,512(sp)
    80004f16:	ffce                	sd	s3,504(sp)
    80004f18:	fbd2                	sd	s4,496(sp)
    80004f1a:	f7d6                	sd	s5,488(sp)
    80004f1c:	f3da                	sd	s6,480(sp)
    80004f1e:	efde                	sd	s7,472(sp)
    80004f20:	ebe2                	sd	s8,464(sp)
    80004f22:	e7e6                	sd	s9,456(sp)
    80004f24:	e3ea                	sd	s10,448(sp)
    80004f26:	ff6e                	sd	s11,440(sp)
    80004f28:	1400                	addi	s0,sp,544
    80004f2a:	892a                	mv	s2,a0
    80004f2c:	dea43423          	sd	a0,-536(s0)
    80004f30:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	a78080e7          	jalr	-1416(ra) # 800019ac <myproc>
    80004f3c:	84aa                	mv	s1,a0

  begin_op();
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	47e080e7          	jalr	1150(ra) # 800043bc <begin_op>

  if((ip = namei(path)) == 0){
    80004f46:	854a                	mv	a0,s2
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	258080e7          	jalr	600(ra) # 800041a0 <namei>
    80004f50:	c93d                	beqz	a0,80004fc6 <exec+0xc4>
    80004f52:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	aa6080e7          	jalr	-1370(ra) # 800039fa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f5c:	04000713          	li	a4,64
    80004f60:	4681                	li	a3,0
    80004f62:	e5040613          	addi	a2,s0,-432
    80004f66:	4581                	li	a1,0
    80004f68:	8556                	mv	a0,s5
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	d44080e7          	jalr	-700(ra) # 80003cae <readi>
    80004f72:	04000793          	li	a5,64
    80004f76:	00f51a63          	bne	a0,a5,80004f8a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f7a:	e5042703          	lw	a4,-432(s0)
    80004f7e:	464c47b7          	lui	a5,0x464c4
    80004f82:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f86:	04f70663          	beq	a4,a5,80004fd2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f8a:	8556                	mv	a0,s5
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	cd0080e7          	jalr	-816(ra) # 80003c5c <iunlockput>
    end_op();
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	4a8080e7          	jalr	1192(ra) # 8000443c <end_op>
  }
  return -1;
    80004f9c:	557d                	li	a0,-1
}
    80004f9e:	21813083          	ld	ra,536(sp)
    80004fa2:	21013403          	ld	s0,528(sp)
    80004fa6:	20813483          	ld	s1,520(sp)
    80004faa:	20013903          	ld	s2,512(sp)
    80004fae:	79fe                	ld	s3,504(sp)
    80004fb0:	7a5e                	ld	s4,496(sp)
    80004fb2:	7abe                	ld	s5,488(sp)
    80004fb4:	7b1e                	ld	s6,480(sp)
    80004fb6:	6bfe                	ld	s7,472(sp)
    80004fb8:	6c5e                	ld	s8,464(sp)
    80004fba:	6cbe                	ld	s9,456(sp)
    80004fbc:	6d1e                	ld	s10,448(sp)
    80004fbe:	7dfa                	ld	s11,440(sp)
    80004fc0:	22010113          	addi	sp,sp,544
    80004fc4:	8082                	ret
    end_op();
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	476080e7          	jalr	1142(ra) # 8000443c <end_op>
    return -1;
    80004fce:	557d                	li	a0,-1
    80004fd0:	b7f9                	j	80004f9e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	a9c080e7          	jalr	-1380(ra) # 80001a70 <proc_pagetable>
    80004fdc:	8b2a                	mv	s6,a0
    80004fde:	d555                	beqz	a0,80004f8a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe0:	e7042783          	lw	a5,-400(s0)
    80004fe4:	e8845703          	lhu	a4,-376(s0)
    80004fe8:	c735                	beqz	a4,80005054 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fea:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fec:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ff0:	6a05                	lui	s4,0x1
    80004ff2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ff6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ffa:	6d85                	lui	s11,0x1
    80004ffc:	7d7d                	lui	s10,0xfffff
    80004ffe:	a481                	j	8000523e <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005000:	00003517          	auipc	a0,0x3
    80005004:	6f050513          	addi	a0,a0,1776 # 800086f0 <syscalls+0x2a0>
    80005008:	ffffb097          	auipc	ra,0xffffb
    8000500c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005010:	874a                	mv	a4,s2
    80005012:	009c86bb          	addw	a3,s9,s1
    80005016:	4581                	li	a1,0
    80005018:	8556                	mv	a0,s5
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	c94080e7          	jalr	-876(ra) # 80003cae <readi>
    80005022:	2501                	sext.w	a0,a0
    80005024:	1aa91a63          	bne	s2,a0,800051d8 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005028:	009d84bb          	addw	s1,s11,s1
    8000502c:	013d09bb          	addw	s3,s10,s3
    80005030:	1f74f763          	bgeu	s1,s7,8000521e <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005034:	02049593          	slli	a1,s1,0x20
    80005038:	9181                	srli	a1,a1,0x20
    8000503a:	95e2                	add	a1,a1,s8
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	01e080e7          	jalr	30(ra) # 8000105c <walkaddr>
    80005046:	862a                	mv	a2,a0
    if(pa == 0)
    80005048:	dd45                	beqz	a0,80005000 <exec+0xfe>
      n = PGSIZE;
    8000504a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000504c:	fd49f2e3          	bgeu	s3,s4,80005010 <exec+0x10e>
      n = sz - i;
    80005050:	894e                	mv	s2,s3
    80005052:	bf7d                	j	80005010 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005054:	4901                	li	s2,0
  iunlockput(ip);
    80005056:	8556                	mv	a0,s5
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	c04080e7          	jalr	-1020(ra) # 80003c5c <iunlockput>
  end_op();
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	3dc080e7          	jalr	988(ra) # 8000443c <end_op>
  p = myproc();
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	944080e7          	jalr	-1724(ra) # 800019ac <myproc>
    80005070:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005072:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005076:	6785                	lui	a5,0x1
    80005078:	17fd                	addi	a5,a5,-1
    8000507a:	993e                	add	s2,s2,a5
    8000507c:	77fd                	lui	a5,0xfffff
    8000507e:	00f977b3          	and	a5,s2,a5
    80005082:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005086:	4691                	li	a3,4
    80005088:	6609                	lui	a2,0x2
    8000508a:	963e                	add	a2,a2,a5
    8000508c:	85be                	mv	a1,a5
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	380080e7          	jalr	896(ra) # 80001410 <uvmalloc>
    80005098:	8c2a                	mv	s8,a0
  ip = 0;
    8000509a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000509c:	12050e63          	beqz	a0,800051d8 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050a0:	75f9                	lui	a1,0xffffe
    800050a2:	95aa                	add	a1,a1,a0
    800050a4:	855a                	mv	a0,s6
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	590080e7          	jalr	1424(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800050ae:	7afd                	lui	s5,0xfffff
    800050b0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050b2:	df043783          	ld	a5,-528(s0)
    800050b6:	6388                	ld	a0,0(a5)
    800050b8:	c925                	beqz	a0,80005128 <exec+0x226>
    800050ba:	e9040993          	addi	s3,s0,-368
    800050be:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050c2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	d88080e7          	jalr	-632(ra) # 80000e4e <strlen>
    800050ce:	0015079b          	addiw	a5,a0,1
    800050d2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050d6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050da:	13596663          	bltu	s2,s5,80005206 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050de:	df043d83          	ld	s11,-528(s0)
    800050e2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050e6:	8552                	mv	a0,s4
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	d66080e7          	jalr	-666(ra) # 80000e4e <strlen>
    800050f0:	0015069b          	addiw	a3,a0,1
    800050f4:	8652                	mv	a2,s4
    800050f6:	85ca                	mv	a1,s2
    800050f8:	855a                	mv	a0,s6
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	56e080e7          	jalr	1390(ra) # 80001668 <copyout>
    80005102:	10054663          	bltz	a0,8000520e <exec+0x30c>
    ustack[argc] = sp;
    80005106:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000510a:	0485                	addi	s1,s1,1
    8000510c:	008d8793          	addi	a5,s11,8
    80005110:	def43823          	sd	a5,-528(s0)
    80005114:	008db503          	ld	a0,8(s11)
    80005118:	c911                	beqz	a0,8000512c <exec+0x22a>
    if(argc >= MAXARG)
    8000511a:	09a1                	addi	s3,s3,8
    8000511c:	fb3c95e3          	bne	s9,s3,800050c6 <exec+0x1c4>
  sz = sz1;
    80005120:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005124:	4a81                	li	s5,0
    80005126:	a84d                	j	800051d8 <exec+0x2d6>
  sp = sz;
    80005128:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000512a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000512c:	00349793          	slli	a5,s1,0x3
    80005130:	f9040713          	addi	a4,s0,-112
    80005134:	97ba                	add	a5,a5,a4
    80005136:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc5a0>
  sp -= (argc+1) * sizeof(uint64);
    8000513a:	00148693          	addi	a3,s1,1
    8000513e:	068e                	slli	a3,a3,0x3
    80005140:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005144:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005148:	01597663          	bgeu	s2,s5,80005154 <exec+0x252>
  sz = sz1;
    8000514c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005150:	4a81                	li	s5,0
    80005152:	a059                	j	800051d8 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005154:	e9040613          	addi	a2,s0,-368
    80005158:	85ca                	mv	a1,s2
    8000515a:	855a                	mv	a0,s6
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	50c080e7          	jalr	1292(ra) # 80001668 <copyout>
    80005164:	0a054963          	bltz	a0,80005216 <exec+0x314>
  p->trapframe->a1 = sp;
    80005168:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    8000516c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005170:	de843783          	ld	a5,-536(s0)
    80005174:	0007c703          	lbu	a4,0(a5)
    80005178:	cf11                	beqz	a4,80005194 <exec+0x292>
    8000517a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000517c:	02f00693          	li	a3,47
    80005180:	a039                	j	8000518e <exec+0x28c>
      last = s+1;
    80005182:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005186:	0785                	addi	a5,a5,1
    80005188:	fff7c703          	lbu	a4,-1(a5)
    8000518c:	c701                	beqz	a4,80005194 <exec+0x292>
    if(*s == '/')
    8000518e:	fed71ce3          	bne	a4,a3,80005186 <exec+0x284>
    80005192:	bfc5                	j	80005182 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005194:	4641                	li	a2,16
    80005196:	de843583          	ld	a1,-536(s0)
    8000519a:	178b8513          	addi	a0,s7,376
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	c7e080e7          	jalr	-898(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051a6:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800051aa:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800051ae:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051b2:	060bb783          	ld	a5,96(s7)
    800051b6:	e6843703          	ld	a4,-408(s0)
    800051ba:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051bc:	060bb783          	ld	a5,96(s7)
    800051c0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051c4:	85ea                	mv	a1,s10
    800051c6:	ffffd097          	auipc	ra,0xffffd
    800051ca:	946080e7          	jalr	-1722(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051ce:	0004851b          	sext.w	a0,s1
    800051d2:	b3f1                	j	80004f9e <exec+0x9c>
    800051d4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051d8:	df843583          	ld	a1,-520(s0)
    800051dc:	855a                	mv	a0,s6
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	92e080e7          	jalr	-1746(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051e6:	da0a92e3          	bnez	s5,80004f8a <exec+0x88>
  return -1;
    800051ea:	557d                	li	a0,-1
    800051ec:	bb4d                	j	80004f9e <exec+0x9c>
    800051ee:	df243c23          	sd	s2,-520(s0)
    800051f2:	b7dd                	j	800051d8 <exec+0x2d6>
    800051f4:	df243c23          	sd	s2,-520(s0)
    800051f8:	b7c5                	j	800051d8 <exec+0x2d6>
    800051fa:	df243c23          	sd	s2,-520(s0)
    800051fe:	bfe9                	j	800051d8 <exec+0x2d6>
    80005200:	df243c23          	sd	s2,-520(s0)
    80005204:	bfd1                	j	800051d8 <exec+0x2d6>
  sz = sz1;
    80005206:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000520a:	4a81                	li	s5,0
    8000520c:	b7f1                	j	800051d8 <exec+0x2d6>
  sz = sz1;
    8000520e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005212:	4a81                	li	s5,0
    80005214:	b7d1                	j	800051d8 <exec+0x2d6>
  sz = sz1;
    80005216:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000521a:	4a81                	li	s5,0
    8000521c:	bf75                	j	800051d8 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000521e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005222:	e0843783          	ld	a5,-504(s0)
    80005226:	0017869b          	addiw	a3,a5,1
    8000522a:	e0d43423          	sd	a3,-504(s0)
    8000522e:	e0043783          	ld	a5,-512(s0)
    80005232:	0387879b          	addiw	a5,a5,56
    80005236:	e8845703          	lhu	a4,-376(s0)
    8000523a:	e0e6dee3          	bge	a3,a4,80005056 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000523e:	2781                	sext.w	a5,a5
    80005240:	e0f43023          	sd	a5,-512(s0)
    80005244:	03800713          	li	a4,56
    80005248:	86be                	mv	a3,a5
    8000524a:	e1840613          	addi	a2,s0,-488
    8000524e:	4581                	li	a1,0
    80005250:	8556                	mv	a0,s5
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	a5c080e7          	jalr	-1444(ra) # 80003cae <readi>
    8000525a:	03800793          	li	a5,56
    8000525e:	f6f51be3          	bne	a0,a5,800051d4 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005262:	e1842783          	lw	a5,-488(s0)
    80005266:	4705                	li	a4,1
    80005268:	fae79de3          	bne	a5,a4,80005222 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000526c:	e4043483          	ld	s1,-448(s0)
    80005270:	e3843783          	ld	a5,-456(s0)
    80005274:	f6f4ede3          	bltu	s1,a5,800051ee <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005278:	e2843783          	ld	a5,-472(s0)
    8000527c:	94be                	add	s1,s1,a5
    8000527e:	f6f4ebe3          	bltu	s1,a5,800051f4 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005282:	de043703          	ld	a4,-544(s0)
    80005286:	8ff9                	and	a5,a5,a4
    80005288:	fbad                	bnez	a5,800051fa <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000528a:	e1c42503          	lw	a0,-484(s0)
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	c58080e7          	jalr	-936(ra) # 80004ee6 <flags2perm>
    80005296:	86aa                	mv	a3,a0
    80005298:	8626                	mv	a2,s1
    8000529a:	85ca                	mv	a1,s2
    8000529c:	855a                	mv	a0,s6
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	172080e7          	jalr	370(ra) # 80001410 <uvmalloc>
    800052a6:	dea43c23          	sd	a0,-520(s0)
    800052aa:	d939                	beqz	a0,80005200 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052ac:	e2843c03          	ld	s8,-472(s0)
    800052b0:	e2042c83          	lw	s9,-480(s0)
    800052b4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052b8:	f60b83e3          	beqz	s7,8000521e <exec+0x31c>
    800052bc:	89de                	mv	s3,s7
    800052be:	4481                	li	s1,0
    800052c0:	bb95                	j	80005034 <exec+0x132>

00000000800052c2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052c2:	7179                	addi	sp,sp,-48
    800052c4:	f406                	sd	ra,40(sp)
    800052c6:	f022                	sd	s0,32(sp)
    800052c8:	ec26                	sd	s1,24(sp)
    800052ca:	e84a                	sd	s2,16(sp)
    800052cc:	1800                	addi	s0,sp,48
    800052ce:	892e                	mv	s2,a1
    800052d0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052d2:	fdc40593          	addi	a1,s0,-36
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	a68080e7          	jalr	-1432(ra) # 80002d3e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052de:	fdc42703          	lw	a4,-36(s0)
    800052e2:	47bd                	li	a5,15
    800052e4:	02e7eb63          	bltu	a5,a4,8000531a <argfd+0x58>
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	6c4080e7          	jalr	1732(ra) # 800019ac <myproc>
    800052f0:	fdc42703          	lw	a4,-36(s0)
    800052f4:	01e70793          	addi	a5,a4,30
    800052f8:	078e                	slli	a5,a5,0x3
    800052fa:	953e                	add	a0,a0,a5
    800052fc:	611c                	ld	a5,0(a0)
    800052fe:	c385                	beqz	a5,8000531e <argfd+0x5c>
    return -1;
  if(pfd)
    80005300:	00090463          	beqz	s2,80005308 <argfd+0x46>
    *pfd = fd;
    80005304:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005308:	4501                	li	a0,0
  if(pf)
    8000530a:	c091                	beqz	s1,8000530e <argfd+0x4c>
    *pf = f;
    8000530c:	e09c                	sd	a5,0(s1)
}
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	64e2                	ld	s1,24(sp)
    80005314:	6942                	ld	s2,16(sp)
    80005316:	6145                	addi	sp,sp,48
    80005318:	8082                	ret
    return -1;
    8000531a:	557d                	li	a0,-1
    8000531c:	bfcd                	j	8000530e <argfd+0x4c>
    8000531e:	557d                	li	a0,-1
    80005320:	b7fd                	j	8000530e <argfd+0x4c>

0000000080005322 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005322:	1101                	addi	sp,sp,-32
    80005324:	ec06                	sd	ra,24(sp)
    80005326:	e822                	sd	s0,16(sp)
    80005328:	e426                	sd	s1,8(sp)
    8000532a:	1000                	addi	s0,sp,32
    8000532c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	67e080e7          	jalr	1662(ra) # 800019ac <myproc>
    80005336:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005338:	0f050793          	addi	a5,a0,240
    8000533c:	4501                	li	a0,0
    8000533e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005340:	6398                	ld	a4,0(a5)
    80005342:	cb19                	beqz	a4,80005358 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005344:	2505                	addiw	a0,a0,1
    80005346:	07a1                	addi	a5,a5,8
    80005348:	fed51ce3          	bne	a0,a3,80005340 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000534c:	557d                	li	a0,-1
}
    8000534e:	60e2                	ld	ra,24(sp)
    80005350:	6442                	ld	s0,16(sp)
    80005352:	64a2                	ld	s1,8(sp)
    80005354:	6105                	addi	sp,sp,32
    80005356:	8082                	ret
      p->ofile[fd] = f;
    80005358:	01e50793          	addi	a5,a0,30
    8000535c:	078e                	slli	a5,a5,0x3
    8000535e:	963e                	add	a2,a2,a5
    80005360:	e204                	sd	s1,0(a2)
      return fd;
    80005362:	b7f5                	j	8000534e <fdalloc+0x2c>

0000000080005364 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005364:	715d                	addi	sp,sp,-80
    80005366:	e486                	sd	ra,72(sp)
    80005368:	e0a2                	sd	s0,64(sp)
    8000536a:	fc26                	sd	s1,56(sp)
    8000536c:	f84a                	sd	s2,48(sp)
    8000536e:	f44e                	sd	s3,40(sp)
    80005370:	f052                	sd	s4,32(sp)
    80005372:	ec56                	sd	s5,24(sp)
    80005374:	e85a                	sd	s6,16(sp)
    80005376:	0880                	addi	s0,sp,80
    80005378:	8b2e                	mv	s6,a1
    8000537a:	89b2                	mv	s3,a2
    8000537c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000537e:	fb040593          	addi	a1,s0,-80
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	e3c080e7          	jalr	-452(ra) # 800041be <nameiparent>
    8000538a:	84aa                	mv	s1,a0
    8000538c:	14050f63          	beqz	a0,800054ea <create+0x186>
    return 0;

  ilock(dp);
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	66a080e7          	jalr	1642(ra) # 800039fa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005398:	4601                	li	a2,0
    8000539a:	fb040593          	addi	a1,s0,-80
    8000539e:	8526                	mv	a0,s1
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	b3e080e7          	jalr	-1218(ra) # 80003ede <dirlookup>
    800053a8:	8aaa                	mv	s5,a0
    800053aa:	c931                	beqz	a0,800053fe <create+0x9a>
    iunlockput(dp);
    800053ac:	8526                	mv	a0,s1
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	8ae080e7          	jalr	-1874(ra) # 80003c5c <iunlockput>
    ilock(ip);
    800053b6:	8556                	mv	a0,s5
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	642080e7          	jalr	1602(ra) # 800039fa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053c0:	000b059b          	sext.w	a1,s6
    800053c4:	4789                	li	a5,2
    800053c6:	02f59563          	bne	a1,a5,800053f0 <create+0x8c>
    800053ca:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6e4>
    800053ce:	37f9                	addiw	a5,a5,-2
    800053d0:	17c2                	slli	a5,a5,0x30
    800053d2:	93c1                	srli	a5,a5,0x30
    800053d4:	4705                	li	a4,1
    800053d6:	00f76d63          	bltu	a4,a5,800053f0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053da:	8556                	mv	a0,s5
    800053dc:	60a6                	ld	ra,72(sp)
    800053de:	6406                	ld	s0,64(sp)
    800053e0:	74e2                	ld	s1,56(sp)
    800053e2:	7942                	ld	s2,48(sp)
    800053e4:	79a2                	ld	s3,40(sp)
    800053e6:	7a02                	ld	s4,32(sp)
    800053e8:	6ae2                	ld	s5,24(sp)
    800053ea:	6b42                	ld	s6,16(sp)
    800053ec:	6161                	addi	sp,sp,80
    800053ee:	8082                	ret
    iunlockput(ip);
    800053f0:	8556                	mv	a0,s5
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	86a080e7          	jalr	-1942(ra) # 80003c5c <iunlockput>
    return 0;
    800053fa:	4a81                	li	s5,0
    800053fc:	bff9                	j	800053da <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053fe:	85da                	mv	a1,s6
    80005400:	4088                	lw	a0,0(s1)
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	45c080e7          	jalr	1116(ra) # 8000385e <ialloc>
    8000540a:	8a2a                	mv	s4,a0
    8000540c:	c539                	beqz	a0,8000545a <create+0xf6>
  ilock(ip);
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	5ec080e7          	jalr	1516(ra) # 800039fa <ilock>
  ip->major = major;
    80005416:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000541a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000541e:	4905                	li	s2,1
    80005420:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005424:	8552                	mv	a0,s4
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	50a080e7          	jalr	1290(ra) # 80003930 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000542e:	000b059b          	sext.w	a1,s6
    80005432:	03258b63          	beq	a1,s2,80005468 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005436:	004a2603          	lw	a2,4(s4)
    8000543a:	fb040593          	addi	a1,s0,-80
    8000543e:	8526                	mv	a0,s1
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	cae080e7          	jalr	-850(ra) # 800040ee <dirlink>
    80005448:	06054f63          	bltz	a0,800054c6 <create+0x162>
  iunlockput(dp);
    8000544c:	8526                	mv	a0,s1
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	80e080e7          	jalr	-2034(ra) # 80003c5c <iunlockput>
  return ip;
    80005456:	8ad2                	mv	s5,s4
    80005458:	b749                	j	800053da <create+0x76>
    iunlockput(dp);
    8000545a:	8526                	mv	a0,s1
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	800080e7          	jalr	-2048(ra) # 80003c5c <iunlockput>
    return 0;
    80005464:	8ad2                	mv	s5,s4
    80005466:	bf95                	j	800053da <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005468:	004a2603          	lw	a2,4(s4)
    8000546c:	00003597          	auipc	a1,0x3
    80005470:	2a458593          	addi	a1,a1,676 # 80008710 <syscalls+0x2c0>
    80005474:	8552                	mv	a0,s4
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	c78080e7          	jalr	-904(ra) # 800040ee <dirlink>
    8000547e:	04054463          	bltz	a0,800054c6 <create+0x162>
    80005482:	40d0                	lw	a2,4(s1)
    80005484:	00003597          	auipc	a1,0x3
    80005488:	29458593          	addi	a1,a1,660 # 80008718 <syscalls+0x2c8>
    8000548c:	8552                	mv	a0,s4
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	c60080e7          	jalr	-928(ra) # 800040ee <dirlink>
    80005496:	02054863          	bltz	a0,800054c6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000549a:	004a2603          	lw	a2,4(s4)
    8000549e:	fb040593          	addi	a1,s0,-80
    800054a2:	8526                	mv	a0,s1
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	c4a080e7          	jalr	-950(ra) # 800040ee <dirlink>
    800054ac:	00054d63          	bltz	a0,800054c6 <create+0x162>
    dp->nlink++;  // for ".."
    800054b0:	04a4d783          	lhu	a5,74(s1)
    800054b4:	2785                	addiw	a5,a5,1
    800054b6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	474080e7          	jalr	1140(ra) # 80003930 <iupdate>
    800054c4:	b761                	j	8000544c <create+0xe8>
  ip->nlink = 0;
    800054c6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054ca:	8552                	mv	a0,s4
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	464080e7          	jalr	1124(ra) # 80003930 <iupdate>
  iunlockput(ip);
    800054d4:	8552                	mv	a0,s4
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	786080e7          	jalr	1926(ra) # 80003c5c <iunlockput>
  iunlockput(dp);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	77c080e7          	jalr	1916(ra) # 80003c5c <iunlockput>
  return 0;
    800054e8:	bdcd                	j	800053da <create+0x76>
    return 0;
    800054ea:	8aaa                	mv	s5,a0
    800054ec:	b5fd                	j	800053da <create+0x76>

00000000800054ee <sys_dup>:
{
    800054ee:	7179                	addi	sp,sp,-48
    800054f0:	f406                	sd	ra,40(sp)
    800054f2:	f022                	sd	s0,32(sp)
    800054f4:	ec26                	sd	s1,24(sp)
    800054f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054f8:	fd840613          	addi	a2,s0,-40
    800054fc:	4581                	li	a1,0
    800054fe:	4501                	li	a0,0
    80005500:	00000097          	auipc	ra,0x0
    80005504:	dc2080e7          	jalr	-574(ra) # 800052c2 <argfd>
    return -1;
    80005508:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000550a:	02054363          	bltz	a0,80005530 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000550e:	fd843503          	ld	a0,-40(s0)
    80005512:	00000097          	auipc	ra,0x0
    80005516:	e10080e7          	jalr	-496(ra) # 80005322 <fdalloc>
    8000551a:	84aa                	mv	s1,a0
    return -1;
    8000551c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000551e:	00054963          	bltz	a0,80005530 <sys_dup+0x42>
  filedup(f);
    80005522:	fd843503          	ld	a0,-40(s0)
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	310080e7          	jalr	784(ra) # 80004836 <filedup>
  return fd;
    8000552e:	87a6                	mv	a5,s1
}
    80005530:	853e                	mv	a0,a5
    80005532:	70a2                	ld	ra,40(sp)
    80005534:	7402                	ld	s0,32(sp)
    80005536:	64e2                	ld	s1,24(sp)
    80005538:	6145                	addi	sp,sp,48
    8000553a:	8082                	ret

000000008000553c <sys_read>:
{
    8000553c:	7179                	addi	sp,sp,-48
    8000553e:	f406                	sd	ra,40(sp)
    80005540:	f022                	sd	s0,32(sp)
    80005542:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005544:	fd840593          	addi	a1,s0,-40
    80005548:	4505                	li	a0,1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	814080e7          	jalr	-2028(ra) # 80002d5e <argaddr>
  argint(2, &n);
    80005552:	fe440593          	addi	a1,s0,-28
    80005556:	4509                	li	a0,2
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	7e6080e7          	jalr	2022(ra) # 80002d3e <argint>
  if(argfd(0, 0, &f) < 0)
    80005560:	fe840613          	addi	a2,s0,-24
    80005564:	4581                	li	a1,0
    80005566:	4501                	li	a0,0
    80005568:	00000097          	auipc	ra,0x0
    8000556c:	d5a080e7          	jalr	-678(ra) # 800052c2 <argfd>
    80005570:	87aa                	mv	a5,a0
    return -1;
    80005572:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005574:	0007cc63          	bltz	a5,8000558c <sys_read+0x50>
  return fileread(f, p, n);
    80005578:	fe442603          	lw	a2,-28(s0)
    8000557c:	fd843583          	ld	a1,-40(s0)
    80005580:	fe843503          	ld	a0,-24(s0)
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	43e080e7          	jalr	1086(ra) # 800049c2 <fileread>
}
    8000558c:	70a2                	ld	ra,40(sp)
    8000558e:	7402                	ld	s0,32(sp)
    80005590:	6145                	addi	sp,sp,48
    80005592:	8082                	ret

0000000080005594 <sys_write>:
{
    80005594:	7179                	addi	sp,sp,-48
    80005596:	f406                	sd	ra,40(sp)
    80005598:	f022                	sd	s0,32(sp)
    8000559a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000559c:	fd840593          	addi	a1,s0,-40
    800055a0:	4505                	li	a0,1
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	7bc080e7          	jalr	1980(ra) # 80002d5e <argaddr>
  argint(2, &n);
    800055aa:	fe440593          	addi	a1,s0,-28
    800055ae:	4509                	li	a0,2
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	78e080e7          	jalr	1934(ra) # 80002d3e <argint>
  if(argfd(0, 0, &f) < 0)
    800055b8:	fe840613          	addi	a2,s0,-24
    800055bc:	4581                	li	a1,0
    800055be:	4501                	li	a0,0
    800055c0:	00000097          	auipc	ra,0x0
    800055c4:	d02080e7          	jalr	-766(ra) # 800052c2 <argfd>
    800055c8:	87aa                	mv	a5,a0
    return -1;
    800055ca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055cc:	0007cc63          	bltz	a5,800055e4 <sys_write+0x50>
  return filewrite(f, p, n);
    800055d0:	fe442603          	lw	a2,-28(s0)
    800055d4:	fd843583          	ld	a1,-40(s0)
    800055d8:	fe843503          	ld	a0,-24(s0)
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	4a8080e7          	jalr	1192(ra) # 80004a84 <filewrite>
}
    800055e4:	70a2                	ld	ra,40(sp)
    800055e6:	7402                	ld	s0,32(sp)
    800055e8:	6145                	addi	sp,sp,48
    800055ea:	8082                	ret

00000000800055ec <sys_close>:
{
    800055ec:	1101                	addi	sp,sp,-32
    800055ee:	ec06                	sd	ra,24(sp)
    800055f0:	e822                	sd	s0,16(sp)
    800055f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055f4:	fe040613          	addi	a2,s0,-32
    800055f8:	fec40593          	addi	a1,s0,-20
    800055fc:	4501                	li	a0,0
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	cc4080e7          	jalr	-828(ra) # 800052c2 <argfd>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005608:	02054463          	bltz	a0,80005630 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000560c:	ffffc097          	auipc	ra,0xffffc
    80005610:	3a0080e7          	jalr	928(ra) # 800019ac <myproc>
    80005614:	fec42783          	lw	a5,-20(s0)
    80005618:	07f9                	addi	a5,a5,30
    8000561a:	078e                	slli	a5,a5,0x3
    8000561c:	97aa                	add	a5,a5,a0
    8000561e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005622:	fe043503          	ld	a0,-32(s0)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	262080e7          	jalr	610(ra) # 80004888 <fileclose>
  return 0;
    8000562e:	4781                	li	a5,0
}
    80005630:	853e                	mv	a0,a5
    80005632:	60e2                	ld	ra,24(sp)
    80005634:	6442                	ld	s0,16(sp)
    80005636:	6105                	addi	sp,sp,32
    80005638:	8082                	ret

000000008000563a <sys_fstat>:
{
    8000563a:	1101                	addi	sp,sp,-32
    8000563c:	ec06                	sd	ra,24(sp)
    8000563e:	e822                	sd	s0,16(sp)
    80005640:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005642:	fe040593          	addi	a1,s0,-32
    80005646:	4505                	li	a0,1
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	716080e7          	jalr	1814(ra) # 80002d5e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005650:	fe840613          	addi	a2,s0,-24
    80005654:	4581                	li	a1,0
    80005656:	4501                	li	a0,0
    80005658:	00000097          	auipc	ra,0x0
    8000565c:	c6a080e7          	jalr	-918(ra) # 800052c2 <argfd>
    80005660:	87aa                	mv	a5,a0
    return -1;
    80005662:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005664:	0007ca63          	bltz	a5,80005678 <sys_fstat+0x3e>
  return filestat(f, st);
    80005668:	fe043583          	ld	a1,-32(s0)
    8000566c:	fe843503          	ld	a0,-24(s0)
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	2e0080e7          	jalr	736(ra) # 80004950 <filestat>
}
    80005678:	60e2                	ld	ra,24(sp)
    8000567a:	6442                	ld	s0,16(sp)
    8000567c:	6105                	addi	sp,sp,32
    8000567e:	8082                	ret

0000000080005680 <sys_link>:
{
    80005680:	7169                	addi	sp,sp,-304
    80005682:	f606                	sd	ra,296(sp)
    80005684:	f222                	sd	s0,288(sp)
    80005686:	ee26                	sd	s1,280(sp)
    80005688:	ea4a                	sd	s2,272(sp)
    8000568a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000568c:	08000613          	li	a2,128
    80005690:	ed040593          	addi	a1,s0,-304
    80005694:	4501                	li	a0,0
    80005696:	ffffd097          	auipc	ra,0xffffd
    8000569a:	736080e7          	jalr	1846(ra) # 80002dcc <argstr>
    return -1;
    8000569e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a0:	10054e63          	bltz	a0,800057bc <sys_link+0x13c>
    800056a4:	08000613          	li	a2,128
    800056a8:	f5040593          	addi	a1,s0,-176
    800056ac:	4505                	li	a0,1
    800056ae:	ffffd097          	auipc	ra,0xffffd
    800056b2:	71e080e7          	jalr	1822(ra) # 80002dcc <argstr>
    return -1;
    800056b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b8:	10054263          	bltz	a0,800057bc <sys_link+0x13c>
  begin_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	d00080e7          	jalr	-768(ra) # 800043bc <begin_op>
  if((ip = namei(old)) == 0){
    800056c4:	ed040513          	addi	a0,s0,-304
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	ad8080e7          	jalr	-1320(ra) # 800041a0 <namei>
    800056d0:	84aa                	mv	s1,a0
    800056d2:	c551                	beqz	a0,8000575e <sys_link+0xde>
  ilock(ip);
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	326080e7          	jalr	806(ra) # 800039fa <ilock>
  if(ip->type == T_DIR){
    800056dc:	04449703          	lh	a4,68(s1)
    800056e0:	4785                	li	a5,1
    800056e2:	08f70463          	beq	a4,a5,8000576a <sys_link+0xea>
  ip->nlink++;
    800056e6:	04a4d783          	lhu	a5,74(s1)
    800056ea:	2785                	addiw	a5,a5,1
    800056ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	23e080e7          	jalr	574(ra) # 80003930 <iupdate>
  iunlock(ip);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	3c0080e7          	jalr	960(ra) # 80003abc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005704:	fd040593          	addi	a1,s0,-48
    80005708:	f5040513          	addi	a0,s0,-176
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	ab2080e7          	jalr	-1358(ra) # 800041be <nameiparent>
    80005714:	892a                	mv	s2,a0
    80005716:	c935                	beqz	a0,8000578a <sys_link+0x10a>
  ilock(dp);
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	2e2080e7          	jalr	738(ra) # 800039fa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005720:	00092703          	lw	a4,0(s2)
    80005724:	409c                	lw	a5,0(s1)
    80005726:	04f71d63          	bne	a4,a5,80005780 <sys_link+0x100>
    8000572a:	40d0                	lw	a2,4(s1)
    8000572c:	fd040593          	addi	a1,s0,-48
    80005730:	854a                	mv	a0,s2
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	9bc080e7          	jalr	-1604(ra) # 800040ee <dirlink>
    8000573a:	04054363          	bltz	a0,80005780 <sys_link+0x100>
  iunlockput(dp);
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	51c080e7          	jalr	1308(ra) # 80003c5c <iunlockput>
  iput(ip);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	46a080e7          	jalr	1130(ra) # 80003bb4 <iput>
  end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	cea080e7          	jalr	-790(ra) # 8000443c <end_op>
  return 0;
    8000575a:	4781                	li	a5,0
    8000575c:	a085                	j	800057bc <sys_link+0x13c>
    end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	cde080e7          	jalr	-802(ra) # 8000443c <end_op>
    return -1;
    80005766:	57fd                	li	a5,-1
    80005768:	a891                	j	800057bc <sys_link+0x13c>
    iunlockput(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	4f0080e7          	jalr	1264(ra) # 80003c5c <iunlockput>
    end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	cc8080e7          	jalr	-824(ra) # 8000443c <end_op>
    return -1;
    8000577c:	57fd                	li	a5,-1
    8000577e:	a83d                	j	800057bc <sys_link+0x13c>
    iunlockput(dp);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	4da080e7          	jalr	1242(ra) # 80003c5c <iunlockput>
  ilock(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	26e080e7          	jalr	622(ra) # 800039fa <ilock>
  ip->nlink--;
    80005794:	04a4d783          	lhu	a5,74(s1)
    80005798:	37fd                	addiw	a5,a5,-1
    8000579a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	190080e7          	jalr	400(ra) # 80003930 <iupdate>
  iunlockput(ip);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	4b2080e7          	jalr	1202(ra) # 80003c5c <iunlockput>
  end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	c8a080e7          	jalr	-886(ra) # 8000443c <end_op>
  return -1;
    800057ba:	57fd                	li	a5,-1
}
    800057bc:	853e                	mv	a0,a5
    800057be:	70b2                	ld	ra,296(sp)
    800057c0:	7412                	ld	s0,288(sp)
    800057c2:	64f2                	ld	s1,280(sp)
    800057c4:	6952                	ld	s2,272(sp)
    800057c6:	6155                	addi	sp,sp,304
    800057c8:	8082                	ret

00000000800057ca <sys_unlink>:
{
    800057ca:	7151                	addi	sp,sp,-240
    800057cc:	f586                	sd	ra,232(sp)
    800057ce:	f1a2                	sd	s0,224(sp)
    800057d0:	eda6                	sd	s1,216(sp)
    800057d2:	e9ca                	sd	s2,208(sp)
    800057d4:	e5ce                	sd	s3,200(sp)
    800057d6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057d8:	08000613          	li	a2,128
    800057dc:	f3040593          	addi	a1,s0,-208
    800057e0:	4501                	li	a0,0
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	5ea080e7          	jalr	1514(ra) # 80002dcc <argstr>
    800057ea:	18054163          	bltz	a0,8000596c <sys_unlink+0x1a2>
  begin_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	bce080e7          	jalr	-1074(ra) # 800043bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057f6:	fb040593          	addi	a1,s0,-80
    800057fa:	f3040513          	addi	a0,s0,-208
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	9c0080e7          	jalr	-1600(ra) # 800041be <nameiparent>
    80005806:	84aa                	mv	s1,a0
    80005808:	c979                	beqz	a0,800058de <sys_unlink+0x114>
  ilock(dp);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	1f0080e7          	jalr	496(ra) # 800039fa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005812:	00003597          	auipc	a1,0x3
    80005816:	efe58593          	addi	a1,a1,-258 # 80008710 <syscalls+0x2c0>
    8000581a:	fb040513          	addi	a0,s0,-80
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	6a6080e7          	jalr	1702(ra) # 80003ec4 <namecmp>
    80005826:	14050a63          	beqz	a0,8000597a <sys_unlink+0x1b0>
    8000582a:	00003597          	auipc	a1,0x3
    8000582e:	eee58593          	addi	a1,a1,-274 # 80008718 <syscalls+0x2c8>
    80005832:	fb040513          	addi	a0,s0,-80
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	68e080e7          	jalr	1678(ra) # 80003ec4 <namecmp>
    8000583e:	12050e63          	beqz	a0,8000597a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005842:	f2c40613          	addi	a2,s0,-212
    80005846:	fb040593          	addi	a1,s0,-80
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	692080e7          	jalr	1682(ra) # 80003ede <dirlookup>
    80005854:	892a                	mv	s2,a0
    80005856:	12050263          	beqz	a0,8000597a <sys_unlink+0x1b0>
  ilock(ip);
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	1a0080e7          	jalr	416(ra) # 800039fa <ilock>
  if(ip->nlink < 1)
    80005862:	04a91783          	lh	a5,74(s2)
    80005866:	08f05263          	blez	a5,800058ea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000586a:	04491703          	lh	a4,68(s2)
    8000586e:	4785                	li	a5,1
    80005870:	08f70563          	beq	a4,a5,800058fa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005874:	4641                	li	a2,16
    80005876:	4581                	li	a1,0
    80005878:	fc040513          	addi	a0,s0,-64
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	456080e7          	jalr	1110(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005884:	4741                	li	a4,16
    80005886:	f2c42683          	lw	a3,-212(s0)
    8000588a:	fc040613          	addi	a2,s0,-64
    8000588e:	4581                	li	a1,0
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	514080e7          	jalr	1300(ra) # 80003da6 <writei>
    8000589a:	47c1                	li	a5,16
    8000589c:	0af51563          	bne	a0,a5,80005946 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058a0:	04491703          	lh	a4,68(s2)
    800058a4:	4785                	li	a5,1
    800058a6:	0af70863          	beq	a4,a5,80005956 <sys_unlink+0x18c>
  iunlockput(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	3b0080e7          	jalr	944(ra) # 80003c5c <iunlockput>
  ip->nlink--;
    800058b4:	04a95783          	lhu	a5,74(s2)
    800058b8:	37fd                	addiw	a5,a5,-1
    800058ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	070080e7          	jalr	112(ra) # 80003930 <iupdate>
  iunlockput(ip);
    800058c8:	854a                	mv	a0,s2
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	392080e7          	jalr	914(ra) # 80003c5c <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	b6a080e7          	jalr	-1174(ra) # 8000443c <end_op>
  return 0;
    800058da:	4501                	li	a0,0
    800058dc:	a84d                	j	8000598e <sys_unlink+0x1c4>
    end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	b5e080e7          	jalr	-1186(ra) # 8000443c <end_op>
    return -1;
    800058e6:	557d                	li	a0,-1
    800058e8:	a05d                	j	8000598e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058ea:	00003517          	auipc	a0,0x3
    800058ee:	e3650513          	addi	a0,a0,-458 # 80008720 <syscalls+0x2d0>
    800058f2:	ffffb097          	auipc	ra,0xffffb
    800058f6:	c4c080e7          	jalr	-948(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058fa:	04c92703          	lw	a4,76(s2)
    800058fe:	02000793          	li	a5,32
    80005902:	f6e7f9e3          	bgeu	a5,a4,80005874 <sys_unlink+0xaa>
    80005906:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000590a:	4741                	li	a4,16
    8000590c:	86ce                	mv	a3,s3
    8000590e:	f1840613          	addi	a2,s0,-232
    80005912:	4581                	li	a1,0
    80005914:	854a                	mv	a0,s2
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	398080e7          	jalr	920(ra) # 80003cae <readi>
    8000591e:	47c1                	li	a5,16
    80005920:	00f51b63          	bne	a0,a5,80005936 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005924:	f1845783          	lhu	a5,-232(s0)
    80005928:	e7a1                	bnez	a5,80005970 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000592a:	29c1                	addiw	s3,s3,16
    8000592c:	04c92783          	lw	a5,76(s2)
    80005930:	fcf9ede3          	bltu	s3,a5,8000590a <sys_unlink+0x140>
    80005934:	b781                	j	80005874 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005936:	00003517          	auipc	a0,0x3
    8000593a:	e0250513          	addi	a0,a0,-510 # 80008738 <syscalls+0x2e8>
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005946:	00003517          	auipc	a0,0x3
    8000594a:	e0a50513          	addi	a0,a0,-502 # 80008750 <syscalls+0x300>
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    dp->nlink--;
    80005956:	04a4d783          	lhu	a5,74(s1)
    8000595a:	37fd                	addiw	a5,a5,-1
    8000595c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	fce080e7          	jalr	-50(ra) # 80003930 <iupdate>
    8000596a:	b781                	j	800058aa <sys_unlink+0xe0>
    return -1;
    8000596c:	557d                	li	a0,-1
    8000596e:	a005                	j	8000598e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	2ea080e7          	jalr	746(ra) # 80003c5c <iunlockput>
  iunlockput(dp);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	2e0080e7          	jalr	736(ra) # 80003c5c <iunlockput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	ab8080e7          	jalr	-1352(ra) # 8000443c <end_op>
  return -1;
    8000598c:	557d                	li	a0,-1
}
    8000598e:	70ae                	ld	ra,232(sp)
    80005990:	740e                	ld	s0,224(sp)
    80005992:	64ee                	ld	s1,216(sp)
    80005994:	694e                	ld	s2,208(sp)
    80005996:	69ae                	ld	s3,200(sp)
    80005998:	616d                	addi	sp,sp,240
    8000599a:	8082                	ret

000000008000599c <sys_open>:

uint64
sys_open(void)
{
    8000599c:	7131                	addi	sp,sp,-192
    8000599e:	fd06                	sd	ra,184(sp)
    800059a0:	f922                	sd	s0,176(sp)
    800059a2:	f526                	sd	s1,168(sp)
    800059a4:	f14a                	sd	s2,160(sp)
    800059a6:	ed4e                	sd	s3,152(sp)
    800059a8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059aa:	f4c40593          	addi	a1,s0,-180
    800059ae:	4505                	li	a0,1
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	38e080e7          	jalr	910(ra) # 80002d3e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b8:	08000613          	li	a2,128
    800059bc:	f5040593          	addi	a1,s0,-176
    800059c0:	4501                	li	a0,0
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	40a080e7          	jalr	1034(ra) # 80002dcc <argstr>
    800059ca:	87aa                	mv	a5,a0
    return -1;
    800059cc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059ce:	0a07c963          	bltz	a5,80005a80 <sys_open+0xe4>

  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	9ea080e7          	jalr	-1558(ra) # 800043bc <begin_op>

  if(omode & O_CREATE){
    800059da:	f4c42783          	lw	a5,-180(s0)
    800059de:	2007f793          	andi	a5,a5,512
    800059e2:	cfc5                	beqz	a5,80005a9a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059e4:	4681                	li	a3,0
    800059e6:	4601                	li	a2,0
    800059e8:	4589                	li	a1,2
    800059ea:	f5040513          	addi	a0,s0,-176
    800059ee:	00000097          	auipc	ra,0x0
    800059f2:	976080e7          	jalr	-1674(ra) # 80005364 <create>
    800059f6:	84aa                	mv	s1,a0
    if(ip == 0){
    800059f8:	c959                	beqz	a0,80005a8e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059fa:	04449703          	lh	a4,68(s1)
    800059fe:	478d                	li	a5,3
    80005a00:	00f71763          	bne	a4,a5,80005a0e <sys_open+0x72>
    80005a04:	0464d703          	lhu	a4,70(s1)
    80005a08:	47a5                	li	a5,9
    80005a0a:	0ce7ed63          	bltu	a5,a4,80005ae4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	dbe080e7          	jalr	-578(ra) # 800047cc <filealloc>
    80005a16:	89aa                	mv	s3,a0
    80005a18:	10050363          	beqz	a0,80005b1e <sys_open+0x182>
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	906080e7          	jalr	-1786(ra) # 80005322 <fdalloc>
    80005a24:	892a                	mv	s2,a0
    80005a26:	0e054763          	bltz	a0,80005b14 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a2a:	04449703          	lh	a4,68(s1)
    80005a2e:	478d                	li	a5,3
    80005a30:	0cf70563          	beq	a4,a5,80005afa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a34:	4789                	li	a5,2
    80005a36:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a3a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a3e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a42:	f4c42783          	lw	a5,-180(s0)
    80005a46:	0017c713          	xori	a4,a5,1
    80005a4a:	8b05                	andi	a4,a4,1
    80005a4c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a50:	0037f713          	andi	a4,a5,3
    80005a54:	00e03733          	snez	a4,a4
    80005a58:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a5c:	4007f793          	andi	a5,a5,1024
    80005a60:	c791                	beqz	a5,80005a6c <sys_open+0xd0>
    80005a62:	04449703          	lh	a4,68(s1)
    80005a66:	4789                	li	a5,2
    80005a68:	0af70063          	beq	a4,a5,80005b08 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	04e080e7          	jalr	78(ra) # 80003abc <iunlock>
  end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9c6080e7          	jalr	-1594(ra) # 8000443c <end_op>

  return fd;
    80005a7e:	854a                	mv	a0,s2
}
    80005a80:	70ea                	ld	ra,184(sp)
    80005a82:	744a                	ld	s0,176(sp)
    80005a84:	74aa                	ld	s1,168(sp)
    80005a86:	790a                	ld	s2,160(sp)
    80005a88:	69ea                	ld	s3,152(sp)
    80005a8a:	6129                	addi	sp,sp,192
    80005a8c:	8082                	ret
      end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	9ae080e7          	jalr	-1618(ra) # 8000443c <end_op>
      return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	b7e5                	j	80005a80 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a9a:	f5040513          	addi	a0,s0,-176
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	702080e7          	jalr	1794(ra) # 800041a0 <namei>
    80005aa6:	84aa                	mv	s1,a0
    80005aa8:	c905                	beqz	a0,80005ad8 <sys_open+0x13c>
    ilock(ip);
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	f50080e7          	jalr	-176(ra) # 800039fa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ab2:	04449703          	lh	a4,68(s1)
    80005ab6:	4785                	li	a5,1
    80005ab8:	f4f711e3          	bne	a4,a5,800059fa <sys_open+0x5e>
    80005abc:	f4c42783          	lw	a5,-180(s0)
    80005ac0:	d7b9                	beqz	a5,80005a0e <sys_open+0x72>
      iunlockput(ip);
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	198080e7          	jalr	408(ra) # 80003c5c <iunlockput>
      end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	970080e7          	jalr	-1680(ra) # 8000443c <end_op>
      return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	b76d                	j	80005a80 <sys_open+0xe4>
      end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	964080e7          	jalr	-1692(ra) # 8000443c <end_op>
      return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	bf79                	j	80005a80 <sys_open+0xe4>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	176080e7          	jalr	374(ra) # 80003c5c <iunlockput>
    end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	94e080e7          	jalr	-1714(ra) # 8000443c <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	b761                	j	80005a80 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005afa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005afe:	04649783          	lh	a5,70(s1)
    80005b02:	02f99223          	sh	a5,36(s3)
    80005b06:	bf25                	j	80005a3e <sys_open+0xa2>
    itrunc(ip);
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	ffe080e7          	jalr	-2(ra) # 80003b08 <itrunc>
    80005b12:	bfa9                	j	80005a6c <sys_open+0xd0>
      fileclose(f);
    80005b14:	854e                	mv	a0,s3
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	d72080e7          	jalr	-654(ra) # 80004888 <fileclose>
    iunlockput(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	13c080e7          	jalr	316(ra) # 80003c5c <iunlockput>
    end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	914080e7          	jalr	-1772(ra) # 8000443c <end_op>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	b7b9                	j	80005a80 <sys_open+0xe4>

0000000080005b34 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b34:	7175                	addi	sp,sp,-144
    80005b36:	e506                	sd	ra,136(sp)
    80005b38:	e122                	sd	s0,128(sp)
    80005b3a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	880080e7          	jalr	-1920(ra) # 800043bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b44:	08000613          	li	a2,128
    80005b48:	f7040593          	addi	a1,s0,-144
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	27e080e7          	jalr	638(ra) # 80002dcc <argstr>
    80005b56:	02054963          	bltz	a0,80005b88 <sys_mkdir+0x54>
    80005b5a:	4681                	li	a3,0
    80005b5c:	4601                	li	a2,0
    80005b5e:	4585                	li	a1,1
    80005b60:	f7040513          	addi	a0,s0,-144
    80005b64:	00000097          	auipc	ra,0x0
    80005b68:	800080e7          	jalr	-2048(ra) # 80005364 <create>
    80005b6c:	cd11                	beqz	a0,80005b88 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	0ee080e7          	jalr	238(ra) # 80003c5c <iunlockput>
  end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	8c6080e7          	jalr	-1850(ra) # 8000443c <end_op>
  return 0;
    80005b7e:	4501                	li	a0,0
}
    80005b80:	60aa                	ld	ra,136(sp)
    80005b82:	640a                	ld	s0,128(sp)
    80005b84:	6149                	addi	sp,sp,144
    80005b86:	8082                	ret
    end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	8b4080e7          	jalr	-1868(ra) # 8000443c <end_op>
    return -1;
    80005b90:	557d                	li	a0,-1
    80005b92:	b7fd                	j	80005b80 <sys_mkdir+0x4c>

0000000080005b94 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b94:	7135                	addi	sp,sp,-160
    80005b96:	ed06                	sd	ra,152(sp)
    80005b98:	e922                	sd	s0,144(sp)
    80005b9a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	820080e7          	jalr	-2016(ra) # 800043bc <begin_op>
  argint(1, &major);
    80005ba4:	f6c40593          	addi	a1,s0,-148
    80005ba8:	4505                	li	a0,1
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	194080e7          	jalr	404(ra) # 80002d3e <argint>
  argint(2, &minor);
    80005bb2:	f6840593          	addi	a1,s0,-152
    80005bb6:	4509                	li	a0,2
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	186080e7          	jalr	390(ra) # 80002d3e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bc0:	08000613          	li	a2,128
    80005bc4:	f7040593          	addi	a1,s0,-144
    80005bc8:	4501                	li	a0,0
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	202080e7          	jalr	514(ra) # 80002dcc <argstr>
    80005bd2:	02054b63          	bltz	a0,80005c08 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bd6:	f6841683          	lh	a3,-152(s0)
    80005bda:	f6c41603          	lh	a2,-148(s0)
    80005bde:	458d                	li	a1,3
    80005be0:	f7040513          	addi	a0,s0,-144
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	780080e7          	jalr	1920(ra) # 80005364 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bec:	cd11                	beqz	a0,80005c08 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	06e080e7          	jalr	110(ra) # 80003c5c <iunlockput>
  end_op();
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	846080e7          	jalr	-1978(ra) # 8000443c <end_op>
  return 0;
    80005bfe:	4501                	li	a0,0
}
    80005c00:	60ea                	ld	ra,152(sp)
    80005c02:	644a                	ld	s0,144(sp)
    80005c04:	610d                	addi	sp,sp,160
    80005c06:	8082                	ret
    end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	834080e7          	jalr	-1996(ra) # 8000443c <end_op>
    return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	b7fd                	j	80005c00 <sys_mknod+0x6c>

0000000080005c14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c14:	7135                	addi	sp,sp,-160
    80005c16:	ed06                	sd	ra,152(sp)
    80005c18:	e922                	sd	s0,144(sp)
    80005c1a:	e526                	sd	s1,136(sp)
    80005c1c:	e14a                	sd	s2,128(sp)
    80005c1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	d8c080e7          	jalr	-628(ra) # 800019ac <myproc>
    80005c28:	892a                	mv	s2,a0
  
  begin_op();
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	792080e7          	jalr	1938(ra) # 800043bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c32:	08000613          	li	a2,128
    80005c36:	f6040593          	addi	a1,s0,-160
    80005c3a:	4501                	li	a0,0
    80005c3c:	ffffd097          	auipc	ra,0xffffd
    80005c40:	190080e7          	jalr	400(ra) # 80002dcc <argstr>
    80005c44:	04054b63          	bltz	a0,80005c9a <sys_chdir+0x86>
    80005c48:	f6040513          	addi	a0,s0,-160
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	554080e7          	jalr	1364(ra) # 800041a0 <namei>
    80005c54:	84aa                	mv	s1,a0
    80005c56:	c131                	beqz	a0,80005c9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	da2080e7          	jalr	-606(ra) # 800039fa <ilock>
  if(ip->type != T_DIR){
    80005c60:	04449703          	lh	a4,68(s1)
    80005c64:	4785                	li	a5,1
    80005c66:	04f71063          	bne	a4,a5,80005ca6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c6a:	8526                	mv	a0,s1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	e50080e7          	jalr	-432(ra) # 80003abc <iunlock>
  iput(p->cwd);
    80005c74:	17093503          	ld	a0,368(s2)
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	f3c080e7          	jalr	-196(ra) # 80003bb4 <iput>
  end_op();
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	7bc080e7          	jalr	1980(ra) # 8000443c <end_op>
  p->cwd = ip;
    80005c88:	16993823          	sd	s1,368(s2)
  return 0;
    80005c8c:	4501                	li	a0,0
}
    80005c8e:	60ea                	ld	ra,152(sp)
    80005c90:	644a                	ld	s0,144(sp)
    80005c92:	64aa                	ld	s1,136(sp)
    80005c94:	690a                	ld	s2,128(sp)
    80005c96:	610d                	addi	sp,sp,160
    80005c98:	8082                	ret
    end_op();
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	7a2080e7          	jalr	1954(ra) # 8000443c <end_op>
    return -1;
    80005ca2:	557d                	li	a0,-1
    80005ca4:	b7ed                	j	80005c8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	fb4080e7          	jalr	-76(ra) # 80003c5c <iunlockput>
    end_op();
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	78c080e7          	jalr	1932(ra) # 8000443c <end_op>
    return -1;
    80005cb8:	557d                	li	a0,-1
    80005cba:	bfd1                	j	80005c8e <sys_chdir+0x7a>

0000000080005cbc <sys_exec>:

uint64
sys_exec(void)
{
    80005cbc:	7145                	addi	sp,sp,-464
    80005cbe:	e786                	sd	ra,456(sp)
    80005cc0:	e3a2                	sd	s0,448(sp)
    80005cc2:	ff26                	sd	s1,440(sp)
    80005cc4:	fb4a                	sd	s2,432(sp)
    80005cc6:	f74e                	sd	s3,424(sp)
    80005cc8:	f352                	sd	s4,416(sp)
    80005cca:	ef56                	sd	s5,408(sp)
    80005ccc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cce:	e3840593          	addi	a1,s0,-456
    80005cd2:	4505                	li	a0,1
    80005cd4:	ffffd097          	auipc	ra,0xffffd
    80005cd8:	08a080e7          	jalr	138(ra) # 80002d5e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cdc:	08000613          	li	a2,128
    80005ce0:	f4040593          	addi	a1,s0,-192
    80005ce4:	4501                	li	a0,0
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	0e6080e7          	jalr	230(ra) # 80002dcc <argstr>
    80005cee:	87aa                	mv	a5,a0
    return -1;
    80005cf0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cf2:	0c07c263          	bltz	a5,80005db6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cf6:	10000613          	li	a2,256
    80005cfa:	4581                	li	a1,0
    80005cfc:	e4040513          	addi	a0,s0,-448
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	fd2080e7          	jalr	-46(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d08:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d0c:	89a6                	mv	s3,s1
    80005d0e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d10:	02000a13          	li	s4,32
    80005d14:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d18:	00391793          	slli	a5,s2,0x3
    80005d1c:	e3040593          	addi	a1,s0,-464
    80005d20:	e3843503          	ld	a0,-456(s0)
    80005d24:	953e                	add	a0,a0,a5
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	f7a080e7          	jalr	-134(ra) # 80002ca0 <fetchaddr>
    80005d2e:	02054a63          	bltz	a0,80005d62 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d32:	e3043783          	ld	a5,-464(s0)
    80005d36:	c3b9                	beqz	a5,80005d7c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	dae080e7          	jalr	-594(ra) # 80000ae6 <kalloc>
    80005d40:	85aa                	mv	a1,a0
    80005d42:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d46:	cd11                	beqz	a0,80005d62 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d48:	6605                	lui	a2,0x1
    80005d4a:	e3043503          	ld	a0,-464(s0)
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	fa4080e7          	jalr	-92(ra) # 80002cf2 <fetchstr>
    80005d56:	00054663          	bltz	a0,80005d62 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d5a:	0905                	addi	s2,s2,1
    80005d5c:	09a1                	addi	s3,s3,8
    80005d5e:	fb491be3          	bne	s2,s4,80005d14 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d62:	10048913          	addi	s2,s1,256
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	c531                	beqz	a0,80005db4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	c80080e7          	jalr	-896(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d72:	04a1                	addi	s1,s1,8
    80005d74:	ff2499e3          	bne	s1,s2,80005d66 <sys_exec+0xaa>
  return -1;
    80005d78:	557d                	li	a0,-1
    80005d7a:	a835                	j	80005db6 <sys_exec+0xfa>
      argv[i] = 0;
    80005d7c:	0a8e                	slli	s5,s5,0x3
    80005d7e:	fc040793          	addi	a5,s0,-64
    80005d82:	9abe                	add	s5,s5,a5
    80005d84:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d88:	e4040593          	addi	a1,s0,-448
    80005d8c:	f4040513          	addi	a0,s0,-192
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	172080e7          	jalr	370(ra) # 80004f02 <exec>
    80005d98:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9a:	10048993          	addi	s3,s1,256
    80005d9e:	6088                	ld	a0,0(s1)
    80005da0:	c901                	beqz	a0,80005db0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005da2:	ffffb097          	auipc	ra,0xffffb
    80005da6:	c48080e7          	jalr	-952(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005daa:	04a1                	addi	s1,s1,8
    80005dac:	ff3499e3          	bne	s1,s3,80005d9e <sys_exec+0xe2>
  return ret;
    80005db0:	854a                	mv	a0,s2
    80005db2:	a011                	j	80005db6 <sys_exec+0xfa>
  return -1;
    80005db4:	557d                	li	a0,-1
}
    80005db6:	60be                	ld	ra,456(sp)
    80005db8:	641e                	ld	s0,448(sp)
    80005dba:	74fa                	ld	s1,440(sp)
    80005dbc:	795a                	ld	s2,432(sp)
    80005dbe:	79ba                	ld	s3,424(sp)
    80005dc0:	7a1a                	ld	s4,416(sp)
    80005dc2:	6afa                	ld	s5,408(sp)
    80005dc4:	6179                	addi	sp,sp,464
    80005dc6:	8082                	ret

0000000080005dc8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dc8:	7139                	addi	sp,sp,-64
    80005dca:	fc06                	sd	ra,56(sp)
    80005dcc:	f822                	sd	s0,48(sp)
    80005dce:	f426                	sd	s1,40(sp)
    80005dd0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dd2:	ffffc097          	auipc	ra,0xffffc
    80005dd6:	bda080e7          	jalr	-1062(ra) # 800019ac <myproc>
    80005dda:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ddc:	fd840593          	addi	a1,s0,-40
    80005de0:	4501                	li	a0,0
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	f7c080e7          	jalr	-132(ra) # 80002d5e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dea:	fc840593          	addi	a1,s0,-56
    80005dee:	fd040513          	addi	a0,s0,-48
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	dc6080e7          	jalr	-570(ra) # 80004bb8 <pipealloc>
    return -1;
    80005dfa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dfc:	0c054463          	bltz	a0,80005ec4 <sys_pipe+0xfc>
  fd0 = -1;
    80005e00:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e04:	fd043503          	ld	a0,-48(s0)
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	51a080e7          	jalr	1306(ra) # 80005322 <fdalloc>
    80005e10:	fca42223          	sw	a0,-60(s0)
    80005e14:	08054b63          	bltz	a0,80005eaa <sys_pipe+0xe2>
    80005e18:	fc843503          	ld	a0,-56(s0)
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	506080e7          	jalr	1286(ra) # 80005322 <fdalloc>
    80005e24:	fca42023          	sw	a0,-64(s0)
    80005e28:	06054863          	bltz	a0,80005e98 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2c:	4691                	li	a3,4
    80005e2e:	fc440613          	addi	a2,s0,-60
    80005e32:	fd843583          	ld	a1,-40(s0)
    80005e36:	6ca8                	ld	a0,88(s1)
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	830080e7          	jalr	-2000(ra) # 80001668 <copyout>
    80005e40:	02054063          	bltz	a0,80005e60 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e44:	4691                	li	a3,4
    80005e46:	fc040613          	addi	a2,s0,-64
    80005e4a:	fd843583          	ld	a1,-40(s0)
    80005e4e:	0591                	addi	a1,a1,4
    80005e50:	6ca8                	ld	a0,88(s1)
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	816080e7          	jalr	-2026(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e5a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5c:	06055463          	bgez	a0,80005ec4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e60:	fc442783          	lw	a5,-60(s0)
    80005e64:	07f9                	addi	a5,a5,30
    80005e66:	078e                	slli	a5,a5,0x3
    80005e68:	97a6                	add	a5,a5,s1
    80005e6a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e6e:	fc042503          	lw	a0,-64(s0)
    80005e72:	0579                	addi	a0,a0,30
    80005e74:	050e                	slli	a0,a0,0x3
    80005e76:	94aa                	add	s1,s1,a0
    80005e78:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e7c:	fd043503          	ld	a0,-48(s0)
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	a08080e7          	jalr	-1528(ra) # 80004888 <fileclose>
    fileclose(wf);
    80005e88:	fc843503          	ld	a0,-56(s0)
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	9fc080e7          	jalr	-1540(ra) # 80004888 <fileclose>
    return -1;
    80005e94:	57fd                	li	a5,-1
    80005e96:	a03d                	j	80005ec4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e98:	fc442783          	lw	a5,-60(s0)
    80005e9c:	0007c763          	bltz	a5,80005eaa <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ea0:	07f9                	addi	a5,a5,30
    80005ea2:	078e                	slli	a5,a5,0x3
    80005ea4:	94be                	add	s1,s1,a5
    80005ea6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005eaa:	fd043503          	ld	a0,-48(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	9da080e7          	jalr	-1574(ra) # 80004888 <fileclose>
    fileclose(wf);
    80005eb6:	fc843503          	ld	a0,-56(s0)
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	9ce080e7          	jalr	-1586(ra) # 80004888 <fileclose>
    return -1;
    80005ec2:	57fd                	li	a5,-1
}
    80005ec4:	853e                	mv	a0,a5
    80005ec6:	70e2                	ld	ra,56(sp)
    80005ec8:	7442                	ld	s0,48(sp)
    80005eca:	74a2                	ld	s1,40(sp)
    80005ecc:	6121                	addi	sp,sp,64
    80005ece:	8082                	ret

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	c19fc0ef          	jal	ra,80002b28 <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	6d0c                	ld	a1,24(a0)
    80005f6c:	7110                	ld	a2,32(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	9d8080e7          	jalr	-1576(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	00052023          	sw	zero,0(a0)
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	9a0080e7          	jalr	-1632(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5179b          	slliw	a5,a0,0xd
    80005fec:	0c201537          	lui	a0,0xc201
    80005ff0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ff2:	4148                	lw	a0,4(a0)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	978080e7          	jalr	-1672(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	04a7cc63          	blt	a5,a0,80006088 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006034:	0001c797          	auipc	a5,0x1c
    80006038:	7ec78793          	addi	a5,a5,2028 # 80022820 <disk>
    8000603c:	97aa                	add	a5,a5,a0
    8000603e:	0187c783          	lbu	a5,24(a5)
    80006042:	ebb9                	bnez	a5,80006098 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006044:	00451613          	slli	a2,a0,0x4
    80006048:	0001c797          	auipc	a5,0x1c
    8000604c:	7d878793          	addi	a5,a5,2008 # 80022820 <disk>
    80006050:	6394                	ld	a3,0(a5)
    80006052:	96b2                	add	a3,a3,a2
    80006054:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006058:	6398                	ld	a4,0(a5)
    8000605a:	9732                	add	a4,a4,a2
    8000605c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006060:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006064:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006068:	953e                	add	a0,a0,a5
    8000606a:	4785                	li	a5,1
    8000606c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006070:	0001c517          	auipc	a0,0x1c
    80006074:	7c850513          	addi	a0,a0,1992 # 80022838 <disk+0x18>
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	068080e7          	jalr	104(ra) # 800020e0 <wakeup>
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret
    panic("free_desc 1");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	6d850513          	addi	a0,a0,1752 # 80008760 <syscalls+0x310>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6d850513          	addi	a0,a0,1752 # 80008770 <syscalls+0x320>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>

00000000800060a8 <virtio_disk_init>:
{
    800060a8:	1101                	addi	sp,sp,-32
    800060aa:	ec06                	sd	ra,24(sp)
    800060ac:	e822                	sd	s0,16(sp)
    800060ae:	e426                	sd	s1,8(sp)
    800060b0:	e04a                	sd	s2,0(sp)
    800060b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060b4:	00002597          	auipc	a1,0x2
    800060b8:	6cc58593          	addi	a1,a1,1740 # 80008780 <syscalls+0x330>
    800060bc:	0001d517          	auipc	a0,0x1d
    800060c0:	88c50513          	addi	a0,a0,-1908 # 80022948 <disk+0x128>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a82080e7          	jalr	-1406(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060cc:	100017b7          	lui	a5,0x10001
    800060d0:	4398                	lw	a4,0(a5)
    800060d2:	2701                	sext.w	a4,a4
    800060d4:	747277b7          	lui	a5,0x74727
    800060d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060dc:	14f71c63          	bne	a4,a5,80006234 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060e0:	100017b7          	lui	a5,0x10001
    800060e4:	43dc                	lw	a5,4(a5)
    800060e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e8:	4709                	li	a4,2
    800060ea:	14e79563          	bne	a5,a4,80006234 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	479c                	lw	a5,8(a5)
    800060f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f6:	12e79f63          	bne	a5,a4,80006234 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	47d8                	lw	a4,12(a5)
    80006100:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006102:	554d47b7          	lui	a5,0x554d4
    80006106:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000610a:	12f71563          	bne	a4,a5,80006234 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006116:	4705                	li	a4,1
    80006118:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611a:	470d                	li	a4,3
    8000611c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000611e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006120:	c7ffe737          	lui	a4,0xc7ffe
    80006124:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbdff>
    80006128:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000612a:	2701                	sext.w	a4,a4
    8000612c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612e:	472d                	li	a4,11
    80006130:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006132:	5bbc                	lw	a5,112(a5)
    80006134:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006138:	8ba1                	andi	a5,a5,8
    8000613a:	10078563          	beqz	a5,80006244 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006146:	43fc                	lw	a5,68(a5)
    80006148:	2781                	sext.w	a5,a5
    8000614a:	10079563          	bnez	a5,80006254 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000614e:	100017b7          	lui	a5,0x10001
    80006152:	5bdc                	lw	a5,52(a5)
    80006154:	2781                	sext.w	a5,a5
  if(max == 0)
    80006156:	10078763          	beqz	a5,80006264 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000615a:	471d                	li	a4,7
    8000615c:	10f77c63          	bgeu	a4,a5,80006274 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006160:	ffffb097          	auipc	ra,0xffffb
    80006164:	986080e7          	jalr	-1658(ra) # 80000ae6 <kalloc>
    80006168:	0001c497          	auipc	s1,0x1c
    8000616c:	6b848493          	addi	s1,s1,1720 # 80022820 <disk>
    80006170:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	974080e7          	jalr	-1676(ra) # 80000ae6 <kalloc>
    8000617a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	96a080e7          	jalr	-1686(ra) # 80000ae6 <kalloc>
    80006184:	87aa                	mv	a5,a0
    80006186:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006188:	6088                	ld	a0,0(s1)
    8000618a:	cd6d                	beqz	a0,80006284 <virtio_disk_init+0x1dc>
    8000618c:	0001c717          	auipc	a4,0x1c
    80006190:	69c73703          	ld	a4,1692(a4) # 80022828 <disk+0x8>
    80006194:	cb65                	beqz	a4,80006284 <virtio_disk_init+0x1dc>
    80006196:	c7fd                	beqz	a5,80006284 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006198:	6605                	lui	a2,0x1
    8000619a:	4581                	li	a1,0
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	b36080e7          	jalr	-1226(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061a4:	0001c497          	auipc	s1,0x1c
    800061a8:	67c48493          	addi	s1,s1,1660 # 80022820 <disk>
    800061ac:	6605                	lui	a2,0x1
    800061ae:	4581                	li	a1,0
    800061b0:	6488                	ld	a0,8(s1)
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	b20080e7          	jalr	-1248(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061ba:	6605                	lui	a2,0x1
    800061bc:	4581                	li	a1,0
    800061be:	6888                	ld	a0,16(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b12080e7          	jalr	-1262(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061c8:	100017b7          	lui	a5,0x10001
    800061cc:	4721                	li	a4,8
    800061ce:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061d0:	4098                	lw	a4,0(s1)
    800061d2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061d6:	40d8                	lw	a4,4(s1)
    800061d8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061dc:	6498                	ld	a4,8(s1)
    800061de:	0007069b          	sext.w	a3,a4
    800061e2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061e6:	9701                	srai	a4,a4,0x20
    800061e8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061ec:	6898                	ld	a4,16(s1)
    800061ee:	0007069b          	sext.w	a3,a4
    800061f2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061f6:	9701                	srai	a4,a4,0x20
    800061f8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061fc:	4705                	li	a4,1
    800061fe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006200:	00e48c23          	sb	a4,24(s1)
    80006204:	00e48ca3          	sb	a4,25(s1)
    80006208:	00e48d23          	sb	a4,26(s1)
    8000620c:	00e48da3          	sb	a4,27(s1)
    80006210:	00e48e23          	sb	a4,28(s1)
    80006214:	00e48ea3          	sb	a4,29(s1)
    80006218:	00e48f23          	sb	a4,30(s1)
    8000621c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006220:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006224:	0727a823          	sw	s2,112(a5)
}
    80006228:	60e2                	ld	ra,24(sp)
    8000622a:	6442                	ld	s0,16(sp)
    8000622c:	64a2                	ld	s1,8(sp)
    8000622e:	6902                	ld	s2,0(sp)
    80006230:	6105                	addi	sp,sp,32
    80006232:	8082                	ret
    panic("could not find virtio disk");
    80006234:	00002517          	auipc	a0,0x2
    80006238:	55c50513          	addi	a0,a0,1372 # 80008790 <syscalls+0x340>
    8000623c:	ffffa097          	auipc	ra,0xffffa
    80006240:	302080e7          	jalr	770(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006244:	00002517          	auipc	a0,0x2
    80006248:	56c50513          	addi	a0,a0,1388 # 800087b0 <syscalls+0x360>
    8000624c:	ffffa097          	auipc	ra,0xffffa
    80006250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006254:	00002517          	auipc	a0,0x2
    80006258:	57c50513          	addi	a0,a0,1404 # 800087d0 <syscalls+0x380>
    8000625c:	ffffa097          	auipc	ra,0xffffa
    80006260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006264:	00002517          	auipc	a0,0x2
    80006268:	58c50513          	addi	a0,a0,1420 # 800087f0 <syscalls+0x3a0>
    8000626c:	ffffa097          	auipc	ra,0xffffa
    80006270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006274:	00002517          	auipc	a0,0x2
    80006278:	59c50513          	addi	a0,a0,1436 # 80008810 <syscalls+0x3c0>
    8000627c:	ffffa097          	auipc	ra,0xffffa
    80006280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006284:	00002517          	auipc	a0,0x2
    80006288:	5ac50513          	addi	a0,a0,1452 # 80008830 <syscalls+0x3e0>
    8000628c:	ffffa097          	auipc	ra,0xffffa
    80006290:	2b2080e7          	jalr	690(ra) # 8000053e <panic>

0000000080006294 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006294:	7119                	addi	sp,sp,-128
    80006296:	fc86                	sd	ra,120(sp)
    80006298:	f8a2                	sd	s0,112(sp)
    8000629a:	f4a6                	sd	s1,104(sp)
    8000629c:	f0ca                	sd	s2,96(sp)
    8000629e:	ecce                	sd	s3,88(sp)
    800062a0:	e8d2                	sd	s4,80(sp)
    800062a2:	e4d6                	sd	s5,72(sp)
    800062a4:	e0da                	sd	s6,64(sp)
    800062a6:	fc5e                	sd	s7,56(sp)
    800062a8:	f862                	sd	s8,48(sp)
    800062aa:	f466                	sd	s9,40(sp)
    800062ac:	f06a                	sd	s10,32(sp)
    800062ae:	ec6e                	sd	s11,24(sp)
    800062b0:	0100                	addi	s0,sp,128
    800062b2:	8aaa                	mv	s5,a0
    800062b4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062b6:	00c52d03          	lw	s10,12(a0)
    800062ba:	001d1d1b          	slliw	s10,s10,0x1
    800062be:	1d02                	slli	s10,s10,0x20
    800062c0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062c4:	0001c517          	auipc	a0,0x1c
    800062c8:	68450513          	addi	a0,a0,1668 # 80022948 <disk+0x128>
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	90a080e7          	jalr	-1782(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062d6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062d8:	0001cb97          	auipc	s7,0x1c
    800062dc:	548b8b93          	addi	s7,s7,1352 # 80022820 <disk>
  for(int i = 0; i < 3; i++){
    800062e0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062e2:	0001cc97          	auipc	s9,0x1c
    800062e6:	666c8c93          	addi	s9,s9,1638 # 80022948 <disk+0x128>
    800062ea:	a08d                	j	8000634c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062ec:	00fb8733          	add	a4,s7,a5
    800062f0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062f4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062f6:	0207c563          	bltz	a5,80006320 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062fa:	2905                	addiw	s2,s2,1
    800062fc:	0611                	addi	a2,a2,4
    800062fe:	05690c63          	beq	s2,s6,80006356 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006302:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006304:	0001c717          	auipc	a4,0x1c
    80006308:	51c70713          	addi	a4,a4,1308 # 80022820 <disk>
    8000630c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000630e:	01874683          	lbu	a3,24(a4)
    80006312:	fee9                	bnez	a3,800062ec <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006314:	2785                	addiw	a5,a5,1
    80006316:	0705                	addi	a4,a4,1
    80006318:	fe979be3          	bne	a5,s1,8000630e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000631c:	57fd                	li	a5,-1
    8000631e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006320:	01205d63          	blez	s2,8000633a <virtio_disk_rw+0xa6>
    80006324:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006326:	000a2503          	lw	a0,0(s4)
    8000632a:	00000097          	auipc	ra,0x0
    8000632e:	cfc080e7          	jalr	-772(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    80006332:	2d85                	addiw	s11,s11,1
    80006334:	0a11                	addi	s4,s4,4
    80006336:	ffb918e3          	bne	s2,s11,80006326 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000633a:	85e6                	mv	a1,s9
    8000633c:	0001c517          	auipc	a0,0x1c
    80006340:	4fc50513          	addi	a0,a0,1276 # 80022838 <disk+0x18>
    80006344:	ffffc097          	auipc	ra,0xffffc
    80006348:	d38080e7          	jalr	-712(ra) # 8000207c <sleep>
  for(int i = 0; i < 3; i++){
    8000634c:	f8040a13          	addi	s4,s0,-128
{
    80006350:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006352:	894e                	mv	s2,s3
    80006354:	b77d                	j	80006302 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006356:	f8042583          	lw	a1,-128(s0)
    8000635a:	00a58793          	addi	a5,a1,10
    8000635e:	0792                	slli	a5,a5,0x4

  if(write)
    80006360:	0001c617          	auipc	a2,0x1c
    80006364:	4c060613          	addi	a2,a2,1216 # 80022820 <disk>
    80006368:	00f60733          	add	a4,a2,a5
    8000636c:	018036b3          	snez	a3,s8
    80006370:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006372:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006376:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000637a:	f6078693          	addi	a3,a5,-160
    8000637e:	6218                	ld	a4,0(a2)
    80006380:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006382:	00878513          	addi	a0,a5,8
    80006386:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006388:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000638a:	6208                	ld	a0,0(a2)
    8000638c:	96aa                	add	a3,a3,a0
    8000638e:	4741                	li	a4,16
    80006390:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006392:	4705                	li	a4,1
    80006394:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006398:	f8442703          	lw	a4,-124(s0)
    8000639c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063a0:	0712                	slli	a4,a4,0x4
    800063a2:	953a                	add	a0,a0,a4
    800063a4:	058a8693          	addi	a3,s5,88
    800063a8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800063aa:	6208                	ld	a0,0(a2)
    800063ac:	972a                	add	a4,a4,a0
    800063ae:	40000693          	li	a3,1024
    800063b2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063b4:	001c3c13          	seqz	s8,s8
    800063b8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063ba:	001c6c13          	ori	s8,s8,1
    800063be:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800063c2:	f8842603          	lw	a2,-120(s0)
    800063c6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063ca:	0001c697          	auipc	a3,0x1c
    800063ce:	45668693          	addi	a3,a3,1110 # 80022820 <disk>
    800063d2:	00258713          	addi	a4,a1,2
    800063d6:	0712                	slli	a4,a4,0x4
    800063d8:	9736                	add	a4,a4,a3
    800063da:	587d                	li	a6,-1
    800063dc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063e0:	0612                	slli	a2,a2,0x4
    800063e2:	9532                	add	a0,a0,a2
    800063e4:	f9078793          	addi	a5,a5,-112
    800063e8:	97b6                	add	a5,a5,a3
    800063ea:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800063ec:	629c                	ld	a5,0(a3)
    800063ee:	97b2                	add	a5,a5,a2
    800063f0:	4605                	li	a2,1
    800063f2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063f4:	4509                	li	a0,2
    800063f6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800063fa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063fe:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006402:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006406:	6698                	ld	a4,8(a3)
    80006408:	00275783          	lhu	a5,2(a4)
    8000640c:	8b9d                	andi	a5,a5,7
    8000640e:	0786                	slli	a5,a5,0x1
    80006410:	97ba                	add	a5,a5,a4
    80006412:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006416:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000641a:	6698                	ld	a4,8(a3)
    8000641c:	00275783          	lhu	a5,2(a4)
    80006420:	2785                	addiw	a5,a5,1
    80006422:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006426:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000642a:	100017b7          	lui	a5,0x10001
    8000642e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006432:	004aa783          	lw	a5,4(s5)
    80006436:	02c79163          	bne	a5,a2,80006458 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000643a:	0001c917          	auipc	s2,0x1c
    8000643e:	50e90913          	addi	s2,s2,1294 # 80022948 <disk+0x128>
  while(b->disk == 1) {
    80006442:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006444:	85ca                	mv	a1,s2
    80006446:	8556                	mv	a0,s5
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	c34080e7          	jalr	-972(ra) # 8000207c <sleep>
  while(b->disk == 1) {
    80006450:	004aa783          	lw	a5,4(s5)
    80006454:	fe9788e3          	beq	a5,s1,80006444 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006458:	f8042903          	lw	s2,-128(s0)
    8000645c:	00290793          	addi	a5,s2,2
    80006460:	00479713          	slli	a4,a5,0x4
    80006464:	0001c797          	auipc	a5,0x1c
    80006468:	3bc78793          	addi	a5,a5,956 # 80022820 <disk>
    8000646c:	97ba                	add	a5,a5,a4
    8000646e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006472:	0001c997          	auipc	s3,0x1c
    80006476:	3ae98993          	addi	s3,s3,942 # 80022820 <disk>
    8000647a:	00491713          	slli	a4,s2,0x4
    8000647e:	0009b783          	ld	a5,0(s3)
    80006482:	97ba                	add	a5,a5,a4
    80006484:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006488:	854a                	mv	a0,s2
    8000648a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000648e:	00000097          	auipc	ra,0x0
    80006492:	b98080e7          	jalr	-1128(ra) # 80006026 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006496:	8885                	andi	s1,s1,1
    80006498:	f0ed                	bnez	s1,8000647a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000649a:	0001c517          	auipc	a0,0x1c
    8000649e:	4ae50513          	addi	a0,a0,1198 # 80022948 <disk+0x128>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	7e8080e7          	jalr	2024(ra) # 80000c8a <release>
}
    800064aa:	70e6                	ld	ra,120(sp)
    800064ac:	7446                	ld	s0,112(sp)
    800064ae:	74a6                	ld	s1,104(sp)
    800064b0:	7906                	ld	s2,96(sp)
    800064b2:	69e6                	ld	s3,88(sp)
    800064b4:	6a46                	ld	s4,80(sp)
    800064b6:	6aa6                	ld	s5,72(sp)
    800064b8:	6b06                	ld	s6,64(sp)
    800064ba:	7be2                	ld	s7,56(sp)
    800064bc:	7c42                	ld	s8,48(sp)
    800064be:	7ca2                	ld	s9,40(sp)
    800064c0:	7d02                	ld	s10,32(sp)
    800064c2:	6de2                	ld	s11,24(sp)
    800064c4:	6109                	addi	sp,sp,128
    800064c6:	8082                	ret

00000000800064c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064c8:	1101                	addi	sp,sp,-32
    800064ca:	ec06                	sd	ra,24(sp)
    800064cc:	e822                	sd	s0,16(sp)
    800064ce:	e426                	sd	s1,8(sp)
    800064d0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064d2:	0001c497          	auipc	s1,0x1c
    800064d6:	34e48493          	addi	s1,s1,846 # 80022820 <disk>
    800064da:	0001c517          	auipc	a0,0x1c
    800064de:	46e50513          	addi	a0,a0,1134 # 80022948 <disk+0x128>
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	6f4080e7          	jalr	1780(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064ea:	10001737          	lui	a4,0x10001
    800064ee:	533c                	lw	a5,96(a4)
    800064f0:	8b8d                	andi	a5,a5,3
    800064f2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064f4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064f8:	689c                	ld	a5,16(s1)
    800064fa:	0204d703          	lhu	a4,32(s1)
    800064fe:	0027d783          	lhu	a5,2(a5)
    80006502:	04f70863          	beq	a4,a5,80006552 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006506:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000650a:	6898                	ld	a4,16(s1)
    8000650c:	0204d783          	lhu	a5,32(s1)
    80006510:	8b9d                	andi	a5,a5,7
    80006512:	078e                	slli	a5,a5,0x3
    80006514:	97ba                	add	a5,a5,a4
    80006516:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006518:	00278713          	addi	a4,a5,2
    8000651c:	0712                	slli	a4,a4,0x4
    8000651e:	9726                	add	a4,a4,s1
    80006520:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006524:	e721                	bnez	a4,8000656c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006526:	0789                	addi	a5,a5,2
    80006528:	0792                	slli	a5,a5,0x4
    8000652a:	97a6                	add	a5,a5,s1
    8000652c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000652e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006532:	ffffc097          	auipc	ra,0xffffc
    80006536:	bae080e7          	jalr	-1106(ra) # 800020e0 <wakeup>

    disk.used_idx += 1;
    8000653a:	0204d783          	lhu	a5,32(s1)
    8000653e:	2785                	addiw	a5,a5,1
    80006540:	17c2                	slli	a5,a5,0x30
    80006542:	93c1                	srli	a5,a5,0x30
    80006544:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006548:	6898                	ld	a4,16(s1)
    8000654a:	00275703          	lhu	a4,2(a4)
    8000654e:	faf71ce3          	bne	a4,a5,80006506 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006552:	0001c517          	auipc	a0,0x1c
    80006556:	3f650513          	addi	a0,a0,1014 # 80022948 <disk+0x128>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	730080e7          	jalr	1840(ra) # 80000c8a <release>
}
    80006562:	60e2                	ld	ra,24(sp)
    80006564:	6442                	ld	s0,16(sp)
    80006566:	64a2                	ld	s1,8(sp)
    80006568:	6105                	addi	sp,sp,32
    8000656a:	8082                	ret
      panic("virtio_disk_intr status");
    8000656c:	00002517          	auipc	a0,0x2
    80006570:	2dc50513          	addi	a0,a0,732 # 80008848 <syscalls+0x3f8>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	fca080e7          	jalr	-54(ra) # 8000053e <panic>
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
