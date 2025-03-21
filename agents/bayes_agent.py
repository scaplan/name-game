import random
from collections import Counter
import numpy as np
from agents.agent import Agent


##  Author: Spencer Caplan
##  CUNY Graduate Center


# Bayesian Tipping Point simulation


# Two Bayesian parameters can be tuned here: the prior probability and the update scalar
# I have a fixed ceiling parameter of 0.05 as the probability of encountering a non-dominent name post-convergence
# This is needed to allow any tipping at all


class Bayes_Agent(Agent):

	P_NEW_NAME_UNDER_OLD_MODEL = 0.05


	def __init__(self, num, memlimit, initnamesdist, priorprob=0.8, priorname='old', updateweight=0.1):
		super().__init__(num, memlimit, initnamesdist, 'FIFO', 'BUFFER')
		self.PRIOR = priorprob
		self.PRIORNAME = priorname
		self.seed_full_memory(priorname)
		self.UPDATE_WEIGHT = updateweight


	def __str__(self):
		return self.__class__.__name__ + " " + super().__str__() + " PRIOR: " + str(self.PRIOR)


	def compare_add_name(self, yourName, theirName):
		super().compare_add_name(yourName, theirName)

		if theirName == self.PRIORNAME:
			likelihood = 1 - self.P_NEW_NAME_UNDER_OLD_MODEL
		else:
			likelihood = self.P_NEW_NAME_UNDER_OLD_MODEL
		
		# Bayesian update
		bayes_numerator = likelihood * self.PRIOR
		evidence_denom = (self.PRIOR * likelihood) + ((1 - self.PRIOR) * (1 - likelihood))
		posterior = bayes_numerator / evidence_denom

		raw_update_delta = (self.PRIOR - posterior)
		self.PRIOR = self.PRIOR - (raw_update_delta * self.UPDATE_WEIGHT)

		# mem_as_counter = Counter(self.memory)
		# mem_string = 'Old: ' + str(mem_as_counter.get('old')) + ', New: ' + str(mem_as_counter.get('new'))
		# print(f'{mem_string: <25}', "bayes_num ", f'{bayes_numerator:.2f}', "  denom: ",  f'{evidence_denom:.2f}', '  posterior: ', f'{posterior:.2f}', '   updated prior:', f'{self.PRIOR:.2f}')
		# print(self)



	def get_name(self):
		if len(self.memory) > 0:
			if self.PRIOR >= 0.5:
				return self.PRIORNAME
			else:
				# return self.get_most_frequent_name()
				return 'new'
		else:
			return self.sample_initial_names_distro()




if __name__ == "__main__":
	agent_id = 1
	for prior in np.arange(0.95, 0.68, -0.05):
		for update_scaler in np.arange(0.01, 0.2, 0.01):
			sample_agent = Bayes_Agent(agent_id, 12, ['old']*12, prior, 'old', update_scaler)
			agent_id += 1
			tipped = False
			names_to_flip = 0
			while not tipped:
				sample_agent.compare_add_name('old', 'new')
				names_to_flip += 1
				if sample_agent.get_name() == 'new':
					tipped = True
			print("Prior:", f'{prior: <6.2f}', "Update scaler:", f'{update_scaler: <6.2f}', "   tipped after round:", f'{names_to_flip}')

	# print(sample_agent)

	# sample_agent.run_bayes()
	# for i in range(25):
	# 	sample_agent.compare_add_name('old', 'new')
	# 	print(sample_agent.get_name())
	# 	# print(sample_agent.get_name(), '   ---  ', sample_agent)
	# 	# sample_agent.run_bayes()
	# for i in range(15):
	# 	sample_agent.compare_add_name('old', 'new')
	# 	print(sample_agent.get_name())
	# 	# print(sample_agent.get_name(), '   ---  ', sample_agent)






