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
package org.springframework.samples.petclinic.assistant;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.samples.petclinic.owner.Owner;
import org.springframework.samples.petclinic.owner.OwnerRepository;
import org.springframework.samples.petclinic.owner.Pet;
import org.springframework.samples.petclinic.owner.PetType;
import org.springframework.samples.petclinic.owner.PetTypeRepository;
import org.springframework.samples.petclinic.owner.Visit;
import org.springframework.samples.petclinic.owner.VisitRepository;
import org.springframework.samples.petclinic.vet.Vet;
import org.springframework.samples.petclinic.vet.VetRepository;
import org.springframework.stereotype.Component;

/**
 * Tool methods exposed to the AI assistant via Spring AI's {@code @Tool} annotation. Each
 * method wraps an existing repository call and returns a formatted String result.
 */
@Component
public class AssistantTools {

	private final OwnerRepository ownerRepository;

	private final VetRepository vetRepository;

	private final VisitRepository visitRepository;

	private final PetTypeRepository petTypeRepository;

	public AssistantTools(OwnerRepository ownerRepository, VetRepository vetRepository, VisitRepository visitRepository,
			PetTypeRepository petTypeRepository) {
		this.ownerRepository = ownerRepository;
		this.vetRepository = vetRepository;
		this.visitRepository = visitRepository;
		this.petTypeRepository = petTypeRepository;
	}

	@Tool(description = "Search for pet owners by last name, telephone, or city. All parameters are optional — pass empty string to skip a filter.")
	public String searchOwners(@ToolParam(description = "Owner last name prefix (or empty)") String lastName,
			@ToolParam(description = "Telephone number prefix (or empty)") String telephone,
			@ToolParam(description = "City name prefix (or empty)") String city) {
		Page<Owner> owners = this.ownerRepository.searchOwners(lastName != null ? lastName : "",
				telephone != null ? telephone : "", city != null ? city : "", PageRequest.of(0, 10));
		if (owners.isEmpty()) {
			return "No owners found matching the search criteria.";
		}
		StringBuilder sb = new StringBuilder("Found " + owners.getTotalElements() + " owner(s):\n");
		for (Owner owner : owners) {
			sb.append("- ")
				.append(owner.getFirstName())
				.append(" ")
				.append(owner.getLastName())
				.append(" | City: ")
				.append(owner.getCity())
				.append(" | Tel: ")
				.append(owner.getTelephone())
				.append(" | Details: /owners/")
				.append(owner.getId())
				.append("\n");
		}
		return sb.toString();
	}

	@Tool(description = "Get full details for a pet owner including their pets and visit history.")
	public String getOwnerDetails(@ToolParam(description = "The owner's ID") Integer ownerId) {
		Optional<Owner> opt = this.ownerRepository.findById(ownerId);
		if (opt.isEmpty()) {
			return "Owner not found with ID " + ownerId;
		}
		Owner owner = opt.get();
		StringBuilder sb = new StringBuilder();
		sb.append("Owner: ").append(owner.getFirstName()).append(" ").append(owner.getLastName()).append("\n");
		sb.append("Address: ").append(owner.getAddress()).append(", ").append(owner.getCity()).append("\n");
		sb.append("Telephone: ").append(owner.getTelephone()).append("\n");
		sb.append("Details page: /owners/").append(owner.getId()).append("\n");

		List<Pet> pets = owner.getPets();
		if (pets.isEmpty()) {
			sb.append("No pets registered.\n");
		}
		else {
			sb.append("Pets:\n");
			for (Pet pet : pets) {
				sb.append("  - ")
					.append(pet.getName())
					.append(" (")
					.append(pet.getType() != null ? pet.getType().getName() : "unknown")
					.append(", born ")
					.append(pet.getBirthDate())
					.append(", ID: ")
					.append(pet.getId())
					.append(")\n");
				Collection<Visit> visits = pet.getVisits();
				if (!visits.isEmpty()) {
					for (Visit visit : visits) {
						sb.append("    Visit ")
							.append(visit.getDate())
							.append(": ")
							.append(visit.getDescription())
							.append("\n");
					}
				}
			}
		}
		return sb.toString();
	}

	@Tool(description = "List all veterinarians with their specialties.")
	public String listVets() {
		Collection<Vet> vets = this.vetRepository.findAll();
		if (vets.isEmpty()) {
			return "No veterinarians found.";
		}
		StringBuilder sb = new StringBuilder("Veterinarians:\n");
		for (Vet vet : vets) {
			sb.append("- Dr. ").append(vet.getFirstName()).append(" ").append(vet.getLastName());
			if (vet.getNrOfSpecialties() > 0) {
				String specs = vet.getSpecialties().stream().map(s -> s.getName()).collect(Collectors.joining(", "));
				sb.append(" (").append(specs).append(")");
			}
			sb.append("\n");
		}
		return sb.toString();
	}

	@Tool(description = "Find veterinarians with a specific specialty such as 'radiology', 'surgery', or 'dentistry'.")
	public String findVetsBySpecialty(
			@ToolParam(description = "The specialty name to search for") String specialtyName) {
		Page<Vet> vets = this.vetRepository.findBySpecialtyName(specialtyName, PageRequest.of(0, 20));
		if (vets.isEmpty()) {
			return "No veterinarians found with specialty: " + specialtyName;
		}
		StringBuilder sb = new StringBuilder("Veterinarians with specialty '" + specialtyName + "':\n");
		for (Vet vet : vets) {
			sb.append("- Dr. ").append(vet.getFirstName()).append(" ").append(vet.getLastName()).append("\n");
		}
		return sb.toString();
	}

	@Tool(description = "List all valid pet types (cat, dog, etc.).")
	public String listPetTypes() {
		List<PetType> types = this.petTypeRepository.findPetTypes();
		if (types.isEmpty()) {
			return "No pet types found.";
		}
		return "Available pet types: " + types.stream().map(PetType::getName).collect(Collectors.joining(", "));
	}

	@Tool(description = "Get upcoming visits within the specified number of days from today.")
	public String getUpcomingVisits(@ToolParam(description = "Number of days from today to look ahead") int days) {
		LocalDate start = LocalDate.now();
		LocalDate end = start.plusDays(days);
		Page<Visit> visits = this.visitRepository.findUpcomingVisits(start, end, PageRequest.of(0, 20));
		if (visits.isEmpty()) {
			return "No upcoming visits in the next " + days + " days.";
		}
		DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
		StringBuilder sb = new StringBuilder("Upcoming visits in the next " + days + " days:\n");
		for (Visit visit : visits) {
			sb.append("- ").append(visit.getDate().format(fmt)).append(": ").append(visit.getDescription());
			if (visit.getPet() != null) {
				sb.append(" (Pet: ").append(visit.getPet().getName());
				if (visit.getPet().getOwner() != null) {
					sb.append(", Owner: ").append(visit.getPet().getOwner().getLastName());
				}
				sb.append(")");
			}
			sb.append("\n");
		}
		return sb.toString();
	}

}
