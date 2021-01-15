select study1, study2, overlap, studies1.assocs as n1, studies2.assocs as n2
from (
  select results1.study_id as study1, results2.study_id as study2, count(distinct results1.cpg) as overlap
  from results as results1
    join results as results2 on (results1.cpg=results2.cpg)
    where results1.study_id < results2.study_id
      and results1.p_rank <= 1000 and results2.p_rank <= 1000
    group by results1.study_id, results2.study_id
) pairs
  inner join studies as studies1 on (study1=studies1.study_id)
  inner join studies as studies2 on (study2=studies2.study_id);

