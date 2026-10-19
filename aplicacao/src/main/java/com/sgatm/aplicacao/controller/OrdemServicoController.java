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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import java.util.List;

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

    // Método único de deletar com tratamento de erro
    @GetMapping("/ordens/deletar/{id}")
    public String deletarOrdemServico(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            ordemServicoRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("mensagemSucesso", "Ordem de Serviço removida com sucesso!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("mensagemErro", "Não foi possível remover esta Ordem de Serviço.");
        }
        return "redirect:/ordens";
    }

    // Rota para a página de Relatório / Consulta Parametrizada
    @GetMapping("/ordens/relatorio")
    public String relatorioOrdens(@RequestParam(value = "status", required = false) String status, Model model) {
        List<OrdemServico> ordens;
        
        if (status != null && !status.isEmpty()) {
            ordens = ordemServicoRepository.findByStatus(status);
        } else {
            ordens = ordemServicoRepository.findAll();
        }
        
        model.addAttribute("ordens", ordens);
        model.addAttribute("statusSelecionado", status);
        return "relatorio-ordens";
    }

}