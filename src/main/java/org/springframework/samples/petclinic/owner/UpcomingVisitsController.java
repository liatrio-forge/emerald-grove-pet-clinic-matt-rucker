/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.owner;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * Controller for the Upcoming Visits page.
 */
@Controller
class UpcomingVisitsController {

	private static final int DEFAULT_DAYS = 7;

	private static final int PAGE_SIZE = 5;

	private final VisitRepository visitRepository;

	public UpcomingVisitsController(VisitRepository visitRepository) {
		this.visitRepository = visitRepository;
	}

	@GetMapping("/visits/upcoming")
	public String showUpcomingVisits(@RequestParam(defaultValue = "7") String days,
			@RequestParam(defaultValue = "1") int page, Model model) {
		int daysValue = parseDays(days);
		LocalDate start = LocalDate.now();
		LocalDate end = start.plusDays(daysValue);

		Pageable pageable = PageRequest.of(page - 1, PAGE_SIZE);
		Page<Visit> results = this.visitRepository.findUpcomingVisits(start, end, pageable);

		List<Visit> listVisits = results.getContent();
		model.addAttribute("listVisits", listVisits);
		model.addAttribute("currentPage", page);
		model.addAttribute("totalPages", results.getTotalPages());
		model.addAttribute("totalItems", results.getTotalElements());
		model.addAttribute("days", daysValue);
		return "visits/upcomingVisits";
	}

	private int parseDays(String days) {
		try {
			int value = Integer.parseInt(days);
			return value > 0 ? value : DEFAULT_DAYS;
		}
		catch (NumberFormatException e) {
			return DEFAULT_DAYS;
		}
	}

}
