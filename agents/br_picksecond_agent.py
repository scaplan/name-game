import random
from collections import Counter
from agents.agent import Agent

##  Author: Spencer Caplan
##  CUNY Graduate Center


class BR_Agent_PickSecond(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule, noiseratio):
		super().__init__(num, memlimit, initnamesdist, poprule, updaterule)
		self.NOISYRATIO = noiseratio


	def __str__(self):
		return self.__class__.__name__ + " " + super().__str__() + " DETSTATE: " + str(self.in_deterministic_state())


	def in_deterministic_state(self):
		if self.roundsplayed > 0 and self.check_unique_plurality_item():
			return True
		else:
			return False

	def get_second_frequent_name(self):
		assert len(self.memory) > 0 # can't get names from empty memory!
		c = Counter(self.memory)
		if len(c.keys()) == 1:
			checking_index = 0
		else:
			checking_index = 1
		second_most_frequent_tuple = c.most_common()[checking_index]
		second_most_frequent_tuple = second_most_frequent_tuple[0]
		return second_most_frequent_tuple



	def get_name(self):
		"""
		The agent playing the role of speaker picks a best response strategy. The best
		response strategy is defined as the strategy most frequently observed in previous interactions in
		which that agent was the hearer. An agent’s “memory” stores a record of the strategies observed
		in use by other players, and an agent only updates their memory during interactions in which they
		are the hearer. Agents do not respond to a complete history of past plays; rather, we assume that
		agents determine their best response strategy based only on the past M interactions.
		"""
		if len(self.memory) > 0:
			if random.random() < self.NOISYRATIO:
				# print('getting rando')
				return self.get_second_frequent_name()
			else:
				return self.get_most_frequent_name()
		else:
			return self.sample_initial_names_distro()


