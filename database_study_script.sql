1.
CREATE INDEX idx_student_name ON student(name);
CREATE INDEX idx_hash_student_name ON student USING hash(name);
set enable_seqscan = off;
explain ANALYZE select * from student where name = '7b28d892f4';

2.
CREATE EXTENSION pg_trgm;
CREATE INDEX idx_student_surname_gist ON student USING gist (surname gist_trgm_ops);
SET enable_bitmapscan TO off;
explain ANALYZE select * from student where surname like '7b%';

3.
CREATE INDEX idx_student_phone ON student(phone_number);
explain ANALYZE select * from student where phone_number = '%';

4.
CREATE INDEX idx_student_surname ON student(surname);
CREATE INDEX idx_student_id_exam_result ON exam_result (student_id);
set enable_seqscan = off;
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = off;
explain ANALYZE select * from student join exam_result on student.id = exam_result.student_id where student.surname = '23c51a5bb0';


generate random data

insert into student (name, surname, date_of_birth, phone_number, primary_skill)
select left(md5 (random ()::text),10), left(md5 (random ()::text),10), '2018-01-31'::date +interval '1 mons', left(md5 (random ()::text),10), left(md5 (random ()::text),10)
from generate_series (1,94999)
order by random ();

insert into subject (subject_name, student_id)
select left(md5 (random ()::text),10), floor(random() * 100000 + 1)::int
from generate_series (1,1000)
order by random ();

insert into exam_result (student_id, subject_id, mark)
select floor(random() * 99993 + 7)::int, floor(random() * 998 + 2)::int, floor(random() * 100 + 1)::int
from generate_series (1,1000000)
order by random ();


5. Updating date_time column
UPDATE student SET name = 'edeaaa9c12' WHERE id = 7; --not working
drop  function update_student_updated_datetime() cascade;

CREATE FUNCTION update_student_updated_datetime() RETURNS TRIGGER AS $$
BEGIN
    UPDATE student SET updated_datetime=now() WHERE id=OLD.id;
    RETURN NEW;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER student_update
    after UPDATE of name ON student
    FOR EACH ROW
    EXECUTE FUNCTION update_student_updated_datetime();

UPDATE student SET name = 'edeaaa9c22' WHERE id = 8; --working

6. 
alter table student 
add constraint name_check
CHECK (position('@' in name) = 0 AND position('#' in name) = 0 AND position('$' in name) = 0);

insert into student (name, surname, date_of_birth, phone_number, primary_skill) values ('To@m', 'Kuffer', '2003-06-30', 0993784466, 'signing');

7. join 3 tables - snapshot

select student.name, student.surname, subject.subject_name, exam_result.mark from student 
join subject on subject.student_id = student.id
join exam_result on exam_result.student_id = student.id;

8. 
drop function avg_mark;
CREATE FUNCTION avg_mark(id_value int) RETURNS NUMERIC AS $$
declare
   average numeric;
BEGIN
    SELECT AVG(exam_result.mark) into average from exam_result WHERE exam_result.student_id=id_value;
    RETURN average;
END; $$
LANGUAGE plpgsql;

select avg_mark(75266);

select * from exam_result;

9.

CREATE FUNCTION avg_mark_subject(name_value text) RETURNS NUMERIC AS $$
declare
   average numeric;
BEGIN
    SELECT AVG(exam_result.mark) into average from exam_result 
	join subject on subject.id = exam_result.subject_id
	WHERE subject.subject_name=name_value;
    RETURN average;
END; $$
LANGUAGE plpgsql;

select avg_mark_subject('7a35d34887');

select * from exam_result where student_id = 385;









10.
drop function red_zone;

CREATE FUNCTION red_zone() RETURNS table (
		id int,
		name character varying(30),
		surname character varying(30),
		date_of_birth date,
		phone_number character(10),
		primary_skill text,
		created_datetime timestamp without time zone,
		updated_datetime timestamp without time zone
	) AS $$
BEGIN

return query
select * from student where student.id in (select student_id a from exam_result where mark <= 3 group by student_id having count(mark)>=2);

END; $$
LANGUAGE plpgsql;

select * from red_zone();