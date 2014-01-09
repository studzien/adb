-- Experiment 1

START TRANSACTION;

UPDATE vk
SET vk.detected = true;

CALL rule_1();
CALL rule_2();
CALL rule_3();
CALL rule_4a();
CALL rule_4b();
CALL rule_5a();
CALL rule_6();
CALL rule_6();
CALL rule_7();

CALL rule_phigh();
CALL rule_plow();
CALL rule_poff();

COMMIT;
