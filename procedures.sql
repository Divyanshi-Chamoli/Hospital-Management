CREATE OR REPLACE PROCEDURE admit_patient (
    p_patient_id IN NUMBER,
    p_bed_id IN NUMBER,
    p_doctor_id IN NUMBER
)
AS
    v_bed_status VARCHAR2(20);
    v_patient_count NUMBER;
    v_doctor_count NUMBER;
    v_admission_id NUMBER;
BEGIN

    -- Check whether patient exists
    SELECT COUNT(*)
    INTO v_patient_count
    FROM patient
    WHERE patient_id = p_patient_id;

    IF v_patient_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Patient does not exist');
    END IF;


    -- Check whether doctor exists
    SELECT COUNT(*)
    INTO v_doctor_count
    FROM staff
    WHERE staff_id = p_doctor_id
    AND designation = 'Doctor';

    IF v_doctor_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Doctor does not exist');
    END IF;


    -- Check bed status
    SELECT bed_status
    INTO v_bed_status
    FROM bed
    WHERE bed_id = p_bed_id
    FOR UPDATE;


    IF v_bed_status <> 'AVAILABLE' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Bed is not available');
    END IF;


    -- Generate admission ID
    SELECT admission_seq.NEXTVAL
    INTO v_admission_id
    FROM dual;


    -- Create admission
    INSERT INTO admission (
        admission_id,
        patient_id,
        bed_id,
        doctor_id,
        admission_date,
        admission_status
    )
    VALUES (
        v_admission_id,
        p_patient_id,
        p_bed_id,
        p_doctor_id,
        SYSDATE,
        'ADMITTED'
    );


    -- Change bed status
    UPDATE bed
    SET bed_status = 'OCCUPIED'
    WHERE bed_id = p_bed_id;


    -- Commit both operations
    COMMIT;


    DBMS_OUTPUT.PUT_LINE(
        'Patient admitted successfully. Admission ID: '
        || v_admission_id
    );

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Bed does not exist');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END;
/


CREATE OR REPLACE PROCEDURE discharge_patient (
    p_admission_id IN NUMBER
)
AS
    v_bed_id NUMBER;
    v_status VARCHAR2(20);
BEGIN

    SELECT bed_id, admission_status
    INTO v_bed_id, v_status
    FROM admission
    WHERE admission_id = p_admission_id
    FOR UPDATE;


    IF v_status <> 'ADMITTED' THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Patient is not currently admitted'
        );
    END IF;


    -- Discharge patient
    UPDATE admission
    SET discharge_date = SYSDATE,
        admission_status = 'DISCHARGED'
    WHERE admission_id = p_admission_id;


    -- Free the bed
    UPDATE bed
    SET bed_status = 'AVAILABLE'
    WHERE bed_id = v_bed_id;


    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Patient discharged successfully.'
    );

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20006,
            'Admission does not exist'
        );

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END;
/

