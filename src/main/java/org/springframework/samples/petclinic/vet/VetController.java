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
package org.springframework.samples.petclinic.vet;

import java.util.Collection;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * @author Juergen Hoeller
 * @author Mark Fisher
 * @author Ken Krebs
 * @author Arjen Poutsma
 */
@Controller
class VetController {

	private final VetRepository vetRepository;

	private final SpecialtyRepository specialtyRepository;

	public VetController(VetRepository vetRepository, SpecialtyRepository specialtyRepository) {
		this.vetRepository = vetRepository;
		this.specialtyRepository = specialtyRepository;
	}

	@GetMapping("/vets.html")
	public String showVetList(@RequestParam(defaultValue = "1") int page,
			@RequestParam(defaultValue = "") String filter, Model model) {
		Page<Vet> paginated = findFilteredPaginated(page, filter);
		Collection<Specialty> specialties = this.specialtyRepository.findAll();
		model.addAttribute("specialties", specialties);
		model.addAttribute("currentFilter", filter);
		return addPaginationModel(page, paginated, model);
	}

	private String addPaginationModel(int page, Page<Vet> paginated, Model model) {
		List<Vet> listVets = paginated.getContent();
		model.addAttribute("currentPage", page);
		model.addAttribute("totalPages", paginated.getTotalPages());
		model.addAttribute("totalItems", paginated.getTotalElements());
		model.addAttribute("listVets", listVets);
		return "vets/vetList";
	}

	private Page<Vet> findFilteredPaginated(int page, String filter) {
		int pageSize = 5;
		Pageable pageable = PageRequest.of(page - 1, pageSize);
		if ("none".equalsIgnoreCase(filter)) {
			return this.vetRepository.findByNoSpecialties(pageable);
		}
		if (!filter.isBlank() && isKnownSpecialty(filter)) {
			return this.vetRepository.findBySpecialtyName(filter, pageable);
		}
		return this.vetRepository.findAll(pageable);
	}

	private boolean isKnownSpecialty(String filter) {
		return this.specialtyRepository.findAll().stream().anyMatch(s -> s.getName().equalsIgnoreCase(filter));
	}

	@GetMapping({ "/vets" })
	public @ResponseBody Vets showResourcesVetList(@RequestParam(defaultValue = "") String filter) {
		Vets vets = new Vets();
		Page<Vet> results = findFilteredPaginated(1, filter);
		vets.getVetList().addAll(results.getContent());
		return vets;
	}

}
