-- Migration for UI Overhaul and Domain Separation

-- 1. Add assessment_type to exam_schedules
ALTER TABLE public.exam_schedules
ADD COLUMN IF NOT EXISTS assessment_type TEXT DEFAULT 'exam' CHECK (assessment_type IN ('test', 'exam'));

-- 2. Create function to calculate student fee summary
CREATE OR REPLACE FUNCTION get_student_fee_summary(p_student_id INT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_course_fee NUMERIC(10,2) := 0;
  v_paid_total NUMERIC(10,2) := 0;
  v_due_amount NUMERIC(10,2) := 0;
  v_discount NUMERIC(10,2) := 0;
  v_course_id INT;
BEGIN
  -- Get the student's course fee
  SELECT c.fee, s.course_id INTO v_course_fee, v_course_id 
  FROM students s
  LEFT JOIN courses c ON s.course_id = c.id
  WHERE s.id = p_student_id;

  -- Get total amount paid (sum of 'amount' column) and total discounts
  SELECT 
    COALESCE(SUM(amount), 0), 
    COALESCE(SUM(discount), 0) 
  INTO v_paid_total, v_discount
  FROM fee_payments 
  WHERE student_id = p_student_id;

  -- Calculate due amount (Course Fee - Paid Total - Discount)
  v_due_amount := COALESCE(v_course_fee, 0) - v_paid_total - v_discount;

  -- Handle negative due (overpaid)
  IF v_due_amount < 0 THEN
    v_due_amount := 0;
  END IF;

  RETURN json_build_object(
    'course_fee', COALESCE(v_course_fee, 0),
    'paid_total', v_paid_total,
    'discount', v_discount,
    'due_amount', v_due_amount
  );
END;
$$;
