TYPE
  LOGLEVEL : (CRITICAL, WARNING, INFO, DEBUG) := INFO;
END_TYPE

FUNCTION_BLOCK LOGGER
  VAR_INPUT
    TRIG : BOOL;
    MSG : STRING;
    LEVEL : LOGLEVEL := INFO;
  END_VAR
  VAR
    TRIG0 : BOOL;
  END_VAR

  IF TRIG AND NOT TRIG0 THEN
  {{
   LogMessage(GetFbVar(LEVEL),(char*)GetFbVar(MSG, .body),GetFbVar(MSG, .len));
  }}
  END_IF;
  TRIG0:=TRIG;
END_FUNCTION_BLOCK



FUNCTION_BLOCK python_eval
  VAR_INPUT
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    STATE : DWORD;
    BUFFER : STRING;
    PREBUFFER : STRING;
    TRIGM1 : BOOL;
    TRIGGED : BOOL;
  END_VAR

  {extern void __PythonEvalFB(int, PYTHON_EVAL*);__PythonEvalFB(0, data__);}
END_FUNCTION_BLOCK

FUNCTION_BLOCK python_poll
  VAR_INPUT
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    STATE : DWORD;
    BUFFER : STRING;
    PREBUFFER : STRING;
    TRIGM1 : BOOL;
    TRIGGED : BOOL;
  END_VAR

  {extern void __PythonEvalFB(int, PYTHON_EVAL*);__PythonEvalFB(1,(PYTHON_EVAL*)(void*)data__);}
END_FUNCTION_BLOCK

FUNCTION_BLOCK python_gear
  VAR_INPUT
    N : UINT;
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    py_eval : python_eval;
    COUNTER : UINT;
    ADD10_OUT : UINT;
    EQ13_OUT : BOOL;
    SEL15_OUT : UINT;
    AND7_OUT : BOOL;
  END_VAR

  ADD10_OUT := ADD(COUNTER, 1);
  EQ13_OUT := EQ(N, ADD10_OUT);
  SEL15_OUT := SEL(EQ13_OUT, ADD10_OUT, 0);
  COUNTER := SEL15_OUT;
  AND7_OUT := AND(EQ13_OUT, TRIG);
  py_eval(TRIG := AND7_OUT, CODE := CODE);
  ACK := py_eval.ACK;
  RESULT := py_eval.RESULT;
END_FUNCTION_BLOCK


PROGRAM Mixer
  VAR
    START : BOOL := FALSE;
    STOP : BOOL := FALSE;
    L_LEVEL : BOOL := FALSE;
    H_LEVEL : BOOL := FALSE;
    PUMP_1 : BOOL := FALSE;
    PUMP_2 : BOOL := FALSE;
    MIXER_MOTOR : BOOL := FALSE;
  END_VAR
  VAR
    PT_MIXER_MOTOR : UINT := 10;
    SR0 : SR;
  END_VAR
  VAR
    VALVE : BOOL := FALSE;
  END_VAR
  VAR
    SR1 : SR;
    ET_TON0 : TIME;
    TP0 : TP;
    F_TRIG0 : F_TRIG;
    RS0 : RS;
  END_VAR

  SR0(S1 := NOT(STOP) AND NOT(H_LEVEL) AND (L_LEVEL AND START OR PUMP_1 OR PUMP_1), R := H_LEVEL OR STOP);
  PUMP_1 := SR0.Q1;
  PUMP_2 := SR0.Q1;
  TP0(IN := NOT(VALVE) AND (H_LEVEL AND START OR MIXER_MOTOR), PT := T#8000ms);
  F_TRIG0(CLK := TP0.Q);
  SR1(S1 := NOT(STOP) AND TP0.Q, R := F_TRIG0.Q OR STOP OR VALVE);
  MIXER_MOTOR := SR1.Q1;
  RS0(S := NOT(STOP) AND (NOT(MIXER_MOTOR) AND H_LEVEL AND START OR VALVE), R1 := NOT(L_LEVEL) OR STOP);
  VALVE := RS0.Q1;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : Mixer;
  END_RESOURCE
END_CONFIGURATION