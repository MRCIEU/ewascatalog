
select cpg as ''
from results
where study_id="25325234_maternal_smoking_in_pregnancy_discovery_adjusted_for_current_participant_smoking"
and p < 1e-5
into outfile "cpg-sites.txt"
lines terminated by '\n';

create temporary table siteset (cpg varchar(20));
load data local infile 'cpg-sites.txt' into table siteset lines terminated by '\n';

select results.study_id, count(results.cpg) as overlap, studies.assocs as total
from results
  inner join siteset on (results.cpg=siteset.cpg)
  inner join studies on (results.study_id=studies.study_id)
where results.p_rank <= 1000
group by study_id;

