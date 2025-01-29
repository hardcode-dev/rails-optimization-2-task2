test:
	ruby test_me.rb

bm:
	ruby benchmarking.rb

memory:
	ruby memory_profiler.rb

prof:
	ruby ruby_prof.rb

prof-graph_read:
	open ruby_prof_reports/graph.html

prof-call_stack_read:
	open ruby_prof_reports/call_stack.html

prof-call_grind:
	ruby ruby_prof_grind.rb

prof-call_grind_read:
	qcachegrind ruby_prof_reports/callgrind.out.${P}

.PHONY:	test
