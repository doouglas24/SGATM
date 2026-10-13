package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.OrdemServico;
import com.sgatm_db.aplicacao.repository.ClienteRepository;
import com.sgatm_db.aplicacao.repository.EquipamentoRepository;
import com.sgatm_db.aplicacao.repository.OrdemServicoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class OrdemServicoController {

    @Autowired
    private OrdemServicoRepository ordemServicoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private EquipamentoRepository equipamentoRepository;

    @GetMapping("/ordens")
    public String listarOrdens(Model model) {
        model.addAttribute("ordens", ordemServicoRepository.findAll());
        model.addAttribute("ordemServico", new OrdemServico());
        model.addAttribute("clientes", clienteRepository.findAll());
        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        return "ordens";
    }

    @PostMapping("/ordens")
    public String salvarOrdem(@ModelAttribute OrdemServico ordemServico) {
        ordemServicoRepository.save(ordemServico);
        return "redirect:/ordens";
    }

    @GetMapping("/ordens/deletar/{id}")
    public String deletarOrdem(@PathVariable Long id) {
        ordemServicoRepository.deleteById(id);
        return "redirect:/ordens";
    }
}