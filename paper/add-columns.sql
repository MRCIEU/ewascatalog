alter table studies
  add column assocs int;

update studies left join (
  select study_id, count(distinct(cpg)) as assocs
  from results 
  group by study_id
) study_assocs on study_assocs.study_id = studies.study_id
set studies.assocs = study_assocs.assocs;

alter table results
 add column p_rank int;

update results left join (
  select study_id, cpg,
	 @rank := case when study_id = @last_study
	               then @rank + 1
		       else 1
		       end as p_rank,
	 @last_study := study_id 
  from (
    select study_id, cpg from results order by study_id, (p+0) asc
  ) as results_ordered
  join (select @rank := 1, @last_study := '') as init
) as results_p
on results.study_id = results_p.study_id
   and results.cpg = results_p.cpg
set results.p_rank = results_p.p_rank;
