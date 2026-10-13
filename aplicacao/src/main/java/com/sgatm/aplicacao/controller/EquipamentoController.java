package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.Equipamento;
import com.sgatm_db.aplicacao.repository.ClienteRepository;
import com.sgatm_db.aplicacao.repository.EquipamentoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class EquipamentoController {

    @Autowired
    private EquipamentoRepository equipamentoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @GetMapping("/equipamentos")
    public String listarEquipamentos(Model model) {
        model.addAttribute("equipamentos", equipamentoRepository.findAll());
        model.addAttribute("equipamento", new Equipamento());
        model.addAttribute("clientes", clienteRepository.findAll());
        return "equipamentos";
    }

    @PostMapping("/equipamentos")
    public String salvarEquipamento(@ModelAttribute Equipamento equipamento) {
        equipamentoRepository.save(equipamento);
        return "redirect:/equipamentos";
    }

    @GetMapping("/equipamentos/deletar/{id}")
    public String deletarEquipamento(@PathVariable Long id) {
        equipamentoRepository.deleteById(id);
        return "redirect:/equipamentos";
    }
}